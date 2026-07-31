def replace_lines_and_save(file_name):
    # 构建文件名
    base_name = file_name.split('.')[0]  # 去掉后缀
    r_file = f"{base_name}_r.txt"
    n_file = f"{base_name}_n.txt"
    modified_file = f"{base_name}_modified.txt"  # 新文件名
    
    # 读取原文件
    with open(file_name, 'r', encoding='utf-8') as file:
        original_lines = file.readlines()
    
    # 读取_n文件中的行号
    with open(n_file, 'r', encoding='utf-8') as file:
        line_numbers = list(map(int, file.read().split()))
    
    # 读取_r文件中的替换文本
    with open(r_file, 'r', encoding='utf-8') as file:
        replacement_texts = file.readlines()
    
    # 替换原文件中的行
    for i, line_num in enumerate(line_numbers):
        if 1 <= line_num <= len(original_lines):
            original_lines[line_num - 1] = replacement_texts[i]
        else:
            print(f"警告：行号 {line_num} 超出文件范围，忽略该替换。")
    
    # 将修改后的内容保存到新文件
    with open(modified_file, 'w', encoding='utf-8') as file:
        file.writelines(original_lines)
    
    print(f"替换完成！修改后的文件已保存为：{modified_file}")

# 输入文件名
file_name = input("请输入文件名（包括后缀）：")
replace_lines_and_save(file_name)
