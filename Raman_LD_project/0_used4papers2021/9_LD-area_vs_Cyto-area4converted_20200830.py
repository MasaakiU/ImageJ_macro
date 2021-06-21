# -*- coding: utf-8 -*-

import os, sys 
import glob
import numpy as np
from tkinter import filedialog, Tk
from PIL import Image

#########
# funcs #
#########
# pillowを用いた16bit画像変換
def save_u16_to_tiff(u16in):#, size, tiff_filename):
    """
    Since Pillow has poor support for 16-bit TIFF, I made my own
    save function to properly save a 16-bit TIFF.
    """    # write 16-bit TIFF image
    # PIL interprets mode 'I;16' as "uint16, little-endian"
    w, h = u16in.shape
    return Image.frombytes("I;16", (h, w), u16in.tostring())

    # u16in = u16in.astype(int)
    # img_out = Image.new('I;16', u16in.shape)
    # NUMPY 持ってる場合 # make sure u16in little-endian, output bytes
    # outpil = u16in.astype(u16in.dtype.newbyteorder("<")).tobytes()
    # NUMPY 持ってない場合：何故かエラー出る # little-endian u16 format
    # outpil = struct.pack("<%dH"%(len(u16in)), *u16in)
    # img_out.frombytes(outpil)
    # return(img_out)
    # img_out.save(tiff_filename)
def convert_and_save(file_path, save_path, BIT, conversion_func):
    # open
    im = Image.open(file_path)
    im2darray = np.array(im).astype(float)
    # convert
    im2darray = conversion_func(im2darray)
    # save
    mode_dict = {"L":8, "I;16B":16, "F":32}
    BIT = mode_dict.get(im.mode, None)
    if BIT is None:
        raise Exception("unsupported image type: {0}".format(im.mode))
    elif BIT == 8:
        im2darray[im2darray < 0] = 0
        im2darray[im2darray > 2 ** BIT - 1] = 2 ** BIT - 1
        saving_data = Image.fromarray(im2darray.astype(np.uint8))
    elif BIT == 16:
        im2darray[im2darray < 0] = 0
        im2darray[im2darray >= 2 ** BIT - 1] = 2 ** BIT - 1
        saving_data = save_u16_to_tiff(im2darray.astype(np.uint16))
    elif BIT == 32:
        saving_data = Image.fromarray(im2darray.astype(np.float32))
    saving_data.save(save_path)
    return im2darray

########
# main #
########
# フォルダー処理
default_dir_path = os.getcwd()
root = Tk()
root.withdraw()
master_dir_path = filedialog.askdirectory(initialdir=default_dir_path)
master_dir_name = os.path.basename(master_dir_path)
dir_path_list = glob.glob("{0}/**/".format(master_dir_path), recursive=True)
# select target folder
target_dir_path_list = []       # LD, nonLD
target_file_paths_list = []     # LD, nonLD
for dir_path in dir_path_list:
    file_path_list = glob.glob("{0}/*".format(dir_path), recursive=False)
    L = None
    M = None
    for file_path in file_path_list:
        if file_path.endswith("L_maskedLD.tif"):
            L = file_path
        if file_path.endswith("M_maskedCYTO.tif"):
            M = file_path
    if (L is not None) and (M is not None):
        target_dir_path_list.append(dir_path)
        target_file_paths_list.append([L, M])
target_dir_name_list = [os.path.basename(os.path.dirname(target_dir_path)) for target_dir_path in target_dir_path_list]

# メイン
def func(im2darray):
    return (0.03549337 + 0.41417093 * im2darray ** 2.30570572) / (0.24388687 + im2darray ** 2.30570572)
converted_statistics = "name\tvalid dir name\tstatistic type\tvalue\n"
for target_dir_path, target_dir_name, target_file_paths in zip(target_dir_path_list, target_dir_name_list, target_file_paths_list):
    # フォルダ処理：面倒なので、上書きする（この時点でフォルダ内のファイルは消えないが、後でファイルをsaveするとそれは上書きされる）
    new_dir_name = target_dir_name + "_converted_1"
    new_dir_path = os.path.join(target_dir_path, new_dir_name)
    os.makedirs(new_dir_path, exist_ok=True)
    # SNR MaskedConc
    dir_of_target_dir_path = os.path.dirname(os.path.dirname(target_dir_path))
    dir_name_of_target_dir_path = os.path.basename(dir_of_target_dir_path)
    target_dir_path2 = os.path.join(dir_of_target_dir_path, "{0}_SNR_1".format(dir_name_of_target_dir_path))
    target_file_path2 = os.path.join(target_dir_path2, "{0}_MaskedConc.tiff".format(dir_name_of_target_dir_path))
    target_file_name2 = os.path.basename(target_file_path2)
    target_file_name2_wo_ext, ext2 = os.path.splitext(target_file_name2)
    converted_MaskedConc = convert_and_save(target_file_path2, save_path=os.path.join(new_dir_path, "{0}_MaskedConc_converted{1}".format(target_file_name2_wo_ext, ext2)), BIT=32, conversion_func=func)
    # フィアル
    L_maskedLD_path = target_file_paths[1]
    L_maskedLD_path_wo_ext, L_ext = os.path.splitext(L_maskedLD_path)
    M_maskedCYTO_path = target_file_paths[0]
    M_maskedCYTO_path_wo_ext, M_ext = os.path.splitext(M_maskedCYTO_path)
    # 変換と保存
    converted_im2darray_N = convert_and_save(L_maskedLD_path, save_path=os.path.join(new_dir_path, "{0}_N_maskedLD_converted{1}".format(target_dir_name, L_ext)), BIT=32, conversion_func=func)
    converted_im2darray_O = convert_and_save(M_maskedCYTO_path, save_path=os.path.join(new_dir_path, "{0}_O_maskedCYTO_converted{1}".format(target_dir_name, M_ext)), BIT=32, conversion_func=func)
    # 統計データ書き込み       # name       valid dir name      statistic type      value
    area_N = np.count_nonzero(~np.isnan(converted_im2darray_N))
    area_O = np.count_nonzero(~np.isnan(converted_im2darray_O))
    converted_statistics += "N_maskedLD_converted\t{0}\t{1}\t{2}\n".format(target_dir_name, "average", np.nanmean(converted_im2darray_N))
    converted_statistics += "N_maskedLD_converted\t{0}\t{1}\t{2}\n".format(target_dir_name, "s.d.",    np.nanstd(converted_im2darray_N) * area_N / (area_N - 1))
    converted_statistics += "N_maskedLD_converted\t{0}\t{1}\t{2}\n".format(target_dir_name, "area",    area_N)
    converted_statistics += "O_maskedCYTO_converted\t{0}\t{1}\t{2}\n".format(target_dir_name, "average", np.nanmean(converted_im2darray_O))
    converted_statistics += "O_maskedCYTO_converted\t{0}\t{1}\t{2}\n".format(target_dir_name, "s.d.",    np.nanstd(converted_im2darray_O) * area_O / (area_O - 1))
    converted_statistics += "O_maskedCYTO_converted\t{0}\t{1}\t{2}\n".format(target_dir_name, "area", area_O)
# 統計データ保存
with open(os.path.join(master_dir_path, master_dir_name + "_converted_statistics.txt"), "w") as f:
    f.write(converted_statistics)

    

quit()






