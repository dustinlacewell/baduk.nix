import sys
import numpy as np
import scipy.sparse as sparse
from functools import reduce

input_filename = sys.argv[1]
target_size = int(sys.argv[2])
with open(input_filename) as input_file:
    lines = input_file.read().splitlines()
loc = input_filename.rfind('.')
if loc == -1: loc = len(input_filename)
if len(sys.argv) == 4:
    output_file = open(sys.argv[3] , "w")
else:
    output_file = open(f"{target_size}x{target_size}", "w")

# blocks = (len(lines) - 19) // 8
assert lines[-1].count(' ') == 0, "Error: weight file corrupted."
val_filters = lines[-2].count(' ') + 1
assert val_filters == lines[-3].count(' ') + 1 == 256, "Error: value head filters count is not 256."
val_wts = np.fromstring(lines[-4], sep=' ')
num_inters = len(val_wts) // val_filters
assert num_inters * val_filters == len(val_wts), "Error: value head weights count invalid."

orig_size = int(np.sqrt(num_inters + 0.5))
assert orig_size ** 2 == num_inters, "Error: number of intersections not a square."
size_incr = target_size - orig_size

pol_bias = np.fromstring(lines[-9], sep = ' ')
assert len(pol_bias) == num_inters + 1, "Error: policy bias length mismatch."
pol_wts = np.fromstring(lines[-10], sep = ' ')
pol_filters = 2
assert len(pol_wts) == len(pol_bias) * pol_filters * num_inters, "Error: policy weights count mismatch."

val_wts = val_wts.reshape(val_filters, num_inters)
val_lens = np.sqrt(np.sum(val_wts**2, axis=1))
pol_wts = pol_wts.reshape(num_inters+1, pol_filters*num_inters)
pol_lens = np.sqrt(np.sum(pol_wts**2, axis=1))


def single_step_mat(size, stride): # a single step for the iterative method 子块法
    assert stride, "Error: stride cannot be 0."
    if stride < 0:
        data = [[(size-i+stride)/(size+stride+1) for i in range(size)], [(i+stride+1)/(size+stride+1) for i in range(size)]]
    else:
        assert size >= stride, "Error: stride too large (>orig_size)."
        data = [[min(1,(size-i)/(size-stride+1)) for i in range(size)], [min(1,(i+1)/(size-stride+1)) for i in range(size)]]
    offsets = [0,-stride]
    return sparse.dia_matrix((data,offsets), shape=(size+stride,size))

def single_step_fc_mat(size, stride): # a single step for the iterative method, for policy fc layer 处理策略头362x2x361
    assert stride, "Error: stride cannot be 0."
    assert stride <= 1, "Error: stride too large (>1)."
    rows = []; cols = []; data = []
    target_size = size + stride
    for i in range(target_size):
        for j in range(target_size):
            diff = abs(i-j)
            if diff >= size: continue
            if i < stride or j < stride: # only possible when stride > 0, i.e. expanding board size
                rows.append(i*target_size+j); cols.append(i*size+j); data.append(1)
                assert i*size+j<size**2, [i,j]
            elif i >= size or j >= size:
                rows.append(i*target_size+j); cols.append((i-stride)*size+j-stride); data.append(1)
                assert 0<=(i-stride)*size+j-stride<size**2, [i,j]
            else:
                rows.append(i*target_size+j); rows.append(i*target_size+j)
                cols.append(i*size+j); cols.append((i-stride)*size+j-stride)
                assert i*size+j<size**2 and 0<=(i-stride)*size+j-stride<size**2, [i,j]
                entry = (min(i,j)+1)/(target_size+1-diff) if stride < 0 else (min(i,j)-stride+1)/(size-stride+1-diff) # denom provably nonzero
                data.append(1-entry); data.append(entry)
    return sparse.csr_matrix((data,(rows,cols)), shape=(target_size**2,size**2))

def iter_mat(orig_size, target_size, stride, fc=False): # the overall matrix for the iterative method 逐次子块法
    assert stride > 0, "Error: stride must be positive."
    assert orig_size != target_size, "Error: size must be changed."
    assert (orig_size - target_size) % stride == 0, "Error: size difference must be a multiple of stride."
    sgn = np.sign(target_size - orig_size)
    mat = single_step_fc_mat if fc else single_step_mat
    return reduce(lambda x,y: y*x, [mat(i, sgn*stride) for i in range(orig_size,target_size,sgn*stride)])

def rescale_mat(orig_size, target_size, stride, edgewt=1): # rescaling method 缩图法
    # stride = 2 captures even/odd parity / checkerboard / 网格式
    assert stride > 0, "Error: stride must be positive."
    assert orig_size != target_size, "Error: size must be changed."
    assert (orig_size - target_size) % stride == 0, "Error: size difference must be a multiple of stride."
    rows = []; cols = []; data = [];
    orig_wts = [edgewt] + [1] * (orig_size-2) + [edgewt]
    target_wts = [edgewt] + [1] * (target_size-2) + [edgewt]
    for k in range(stride):
        osize = sum([orig_wts[i] for i in range(k,orig_size,stride)])
        tsize = sum([target_wts[i] for i in range(k,target_size,stride)])
        for i in range(k,orig_size,stride): orig_wts[i] *= tsize
        for i in range(k,target_size,stride): target_wts[i] *= osize
        row = k; col = k
        rem = target_wts[row]; filling_row = True
        while row < target_size and col < orig_size:
            size = orig_wts[col] if filling_row else target_wts[row]
            if rem > 0:
                rows.append(row); cols.append(col)
            if rem >= size:
                data.append(size/target_wts[row]); rem -= size
            else:
                if rem > 0: data.append(rem/target_wts[row]); 
                rem = size - rem
                filling_row = not filling_row
            if filling_row: col += stride
            else: row += stride
    return sparse.csr_matrix((data,(rows,cols)), shape=(target_size,orig_size))

# 指定魔改算法 specify resizing methods
val_w_mat = iter_mat(orig_size,target_size,2) # could also try 亦可尝试 rescale_mat(orig_size,target_size,2,0.5)
pol_w_mat = iter_mat(orig_size,target_size,1,True)
pass_mat = pol_b_mat = iter_mat(orig_size,target_size,1)
fixed_multiplier = False

[pol_bias, pass_bias] = np.split(pol_bias, [-1])
[pol_wts, pass_wts] = np.split(pol_wts, [-1])
print(len(pol_wts))
print(len(pass_wts))

val_wts = val_wts.reshape(val_filters, orig_size, orig_size)
pol_wts = pol_wts.reshape(orig_size, orig_size, pol_filters, orig_size, orig_size).transpose(2,0,3,1,4).reshape(pol_filters, num_inters, num_inters)
# transpose(2,0,3,1,4) means 'xyfXY'->'fxXyY'
pass_wts = pass_wts.reshape(pol_filters, orig_size, orig_size)
pol_bias = pol_bias.reshape(orig_size, orig_size)
new_pol_bias = (pol_b_mat*(pol_bias*pol_b_mat.transpose())).ravel()

lines[-9] = ' '.join([str(b) for b in new_pol_bias]) + ' ' + str(pass_bias[0])

new_val_wts = np.array([(val_w_mat * (wts * val_w_mat.transpose())).ravel() for wts in val_wts])
new_val_lens = np.sqrt(np.sum(new_val_wts**2, axis=1))
for i in range(val_filters):
    new_val_wts[i] *= (orig_size**2/target_size**2 if fixed_multiplier else val_lens[i]/new_val_lens[i])
logs = -np.log(val_lens)
multipliers = (val_lens/new_val_lens)[logs<3]
# print(logs)
print(multipliers)
print('val')
print(np.mean(multipliers))
print(np.var(multipliers))
# for LZ # 205 from 19x19 to 13x13, mean = 1.65, variance = 0.0066
lines[-4] = ' '.join([str(w) for w in new_val_wts.ravel()])

new_pol_wts = np.array([pol_w_mat*(pol_wts[i]*pol_w_mat.transpose()) for i in range(pol_filters)]).reshape(pol_filters, target_size, target_size, target_size, target_size).transpose(1,3,0,2,4).reshape(target_size**2,pol_filters*target_size**2)
new_pass_wts = np.array([pass_mat*(pass_wts[i]*pass_mat.transpose()) for i in range(pol_filters)]).reshape(1,pol_filters*target_size**2)
new_pol_wts = np.concatenate((new_pol_wts,new_pass_wts))
new_pol_lens = np.sqrt(np.sum(new_pol_wts**2, axis=1))
multiplier = np.mean(pol_lens)/np.mean(new_pol_lens)
for i in range(target_size**2+1):
    new_pol_wts[i] *= (orig_size**2/target_size**2 if fixed_multiplier else multiplier)
# logs = -np.log(pol_lens)
# print(logs)
print('pol')
print(np.mean(pol_lens))
print(np.mean(new_pol_lens))
print(multiplier)
print('pol_bias')
print(np.mean(pol_bias))
print(np.mean(new_pol_bias))
print(np.mean(pol_bias)/np.mean(new_pol_bias))
print('')
# for LZ # 205 from 19x19 to 13x13, multiplier = 1.015
lines[-10] = ' '.join([str(w) for w in new_pol_wts.ravel()])

print(lines[-4].count(' '))
print(lines[-9].count(' '))
print(lines[-10].count(' '))

for line in lines:
    output_file.write(line+'\n')
output_file.close()


"""
print(single_step_mat(5, 1).toarray())
print(single_step_mat(5, -1).toarray())
print((single_step_mat(4,-1)*single_step_mat(5,-1)).toarray())
print(iter_mat(5,3,1).toarray())
print((single_step_mat(5,1)*single_step_mat(4,1)).toarray())
print(single_step_mat(9,-2).toarray())
print(single_step_mat(9,2).toarray())
print(rescale_mat(5,10,1).toarray())
print(rescale_mat(10,5,1).toarray())
print(rescale_mat(7,5,1).toarray())
print(rescale_mat(7,5,2,0.5).toarray())
print(rescale_mat(7,5,2).toarray())
print(rescale_mat(7,13,2,0.5).toarray())
print(rescale_mat(7,13,2).toarray())
print(single_step_fc_mat(4,-1).toarray())
print(single_step_fc_mat(2,1).toarray())
"""
