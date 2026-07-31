def process_file(input_filename, keyword):
    # 读取文件
    with open(input_filename, 'r', encoding='utf-8') as file:
        lines = file.readlines()

    # 筛选包含关键字符串的行，并记录行号
    filtered_lines = []
    line_numbers = []
    for index, line in enumerate(lines):
        if keyword in line:
            filtered_lines.append(line)
            line_numbers.append(index + 1)  # 行号从1开始

    # 生成输出文件名
    output_filename = input_filename.rsplit('.', 1)[0] + '_r.txt'
    numbers_filename = input_filename.rsplit('.', 1)[0] + '_n.txt'

    # 将筛选后的行保存到新文件
    with open(output_filename, 'w', encoding='utf-8') as output_file:
        output_file.writelines(filtered_lines)

    # 将行号保存到新文件
    with open(numbers_filename, 'w', encoding='utf-8') as numbers_file:
        numbers_file.write('\n'.join(map(str, line_numbers)))

    print(f"处理完成！结果已保存到文件: {output_filename}")
    print(f"行号已保存到文件: {numbers_filename}")


# 主程序
if __name__ == "__main__":
    # 输入文件名和关键字符串
    input_filename = input("请输入文件名（包括后缀）：")
    keyword = input("请输入关键字符串：")

    # 调用处理函数
    process_file(input_filename, keyword)
