import os
import json
from pathlib import Path

def replace_material_in_files(folder_path, dry_run=True, file_extensions=None):
    """
    将指定文件夹下所有JSON或REND文件中的 "material": "Leaves" 替换为 "material": "Crops"
    
    参数:
        folder_path: 要处理的文件夹路径
        dry_run: 如果为True，只显示将要修改的文件而不实际修改；如果为False，则实际修改文件
        file_extensions: 要处理的文件扩展名列表，默认为 ['.json', '.rend']
    """
    if file_extensions is None:
        file_extensions = ['.json', '.rend']
    
    # 构建文件搜索模式
    all_files = []
    for ext in file_extensions:
        files = list(Path(folder_path).rglob(f"*{ext}"))
        all_files.extend(files)
    
    # 去重
    all_files = list(set(all_files))
    
    if not all_files:
        ext_str = ', '.join(file_extensions)
        print(f"在 {folder_path} 及其子文件夹中未找到 {ext_str} 文件")
        return
    
    print(f"找到 {len(all_files)} 个文件（包括 {', '.join(file_extensions)}）")
    print("开始处理...\n")
    
    modified_count = 0
    skipped_count = 0
    error_count = 0
    
    for file_path in all_files:
        try:
            # 读取文件内容
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 尝试解析为JSON
            try:
                data = json.loads(content)
                
                # 递归替换所有"material"键的值为"Crops"
                def replace_material(obj):
                    modified = False
                    if isinstance(obj, dict):
                        for key, value in list(obj.items()):
                            if key == "material" and value == "Leaves":
                                obj[key] = "Crops"
                                modified = True
                            elif isinstance(value, (dict, list)):
                                if replace_material(value):
                                    modified = True
                    elif isinstance(obj, list):
                        for item in obj:
                            if replace_material(item):
                                modified = True
                    return modified
                
                # 应用替换，检查是否有修改
                has_modification = replace_material(data)
                
                if not has_modification:
                    skipped_count += 1
                    if dry_run:
                        print(f"跳过 (无需修改): {file_path}")
                    continue
                
                # 在预览模式下只显示信息
                if dry_run:
                    print(f"将修改: {file_path}")
                    modified_count += 1
                    continue
                
                # 写回文件
                with open(file_path, 'w', encoding='utf-8') as f:
                    json.dump(data, f, ensure_ascii=False, indent=2)
                
                modified_count += 1
                print(f"已修改 (JSON解析): {file_path}")
                
            except json.JSONDecodeError as e:
                # 如果JSON解析失败，使用文本替换
                print(f"JSON解析失败 ({str(e)}), 尝试文本替换: {file_path}")
                
                # 多种格式的替换
                replacements = [
                    ('"material": "Leaves"', '"material": "Crops"'),
                    ('"material":"Leaves"', '"material":"Crops"'),
                    ("'material': 'Leaves'", '"material": "Crops"'),
                    ('"material" : "Leaves"', '"material" : "Crops"'),  # 带空格
                ]
                
                new_content = content
                has_modification = False
                for old, new in replacements:
                    if old in new_content:
                        new_content = new_content.replace(old, new)
                        has_modification = True
                
                if not has_modification:
                    skipped_count += 1
                    if dry_run:
                        print(f"跳过 (无需修改): {file_path}")
                    continue
                
                if dry_run:
                    print(f"将修改: {file_path}")
                    modified_count += 1
                    continue
                
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                modified_count += 1
                print(f"已修改 (文本替换): {file_path}")
                    
        except Exception as e:
            print(f"处理文件 {file_path} 时出错: {e}")
            error_count += 1
            continue
    
    # 输出统计信息
    print(f"\n{'='*50}")
    print(f"处理完成!")
    print(f"总共找到: {len(all_files)} 个文件")
    print(f"已修改: {modified_count} 个文件")
    print(f"已跳过: {skipped_count} 个文件")
    print(f"出错: {error_count} 个文件")
    print(f"{'='*50}")
    
    if dry_run and modified_count > 0:
        print(f"\n【注意】预览模式：以上 {modified_count} 个文件将被修改，但尚未实际更改。")
        print("如需实际修改，请将 dry_run=False 并再次运行。")
    elif dry_run and modified_count == 0:
        print("\n【提示】预览模式下未发现需要修改的文件。")

def main():
    # 获取用户输入
    folder_path = input("请输入要处理的文件夹路径: ").strip()
    
    # 如果直接按回车，使用当前目录
    if not folder_path:
        folder_path = "."
        print(f"使用当前目录: {os.path.abspath(folder_path)}")
    
    # 检查路径是否存在
    if not os.path.exists(folder_path):
        print(f"错误: 路径 '{folder_path}' 不存在")
        return
    
    if not os.path.isdir(folder_path):
        print(f"错误: '{folder_path}' 不是一个文件夹")
        return
    
    # 询问要处理的文件类型
    print("\n支持的文件类型: .json 和 .rend")
    custom_ext = input("是否自定义扩展名? (y/n, 默认n): ").strip().lower()
    
    if custom_ext == 'y':
        ext_input = input("请输入扩展名（用逗号分隔，如: .json,.rend,.txt）: ").strip()
        file_extensions = [ext.strip() for ext in ext_input.split(',') if ext.strip()]
        # 确保扩展名以点开头
        file_extensions = [ext if ext.startswith('.') else f'.{ext}' for ext in file_extensions]
    else:
        file_extensions = ['.json', '.rend']
    
    print(f"\n将处理以下扩展名的文件: {', '.join(file_extensions)}")
    
    # 询问是否预览
    preview = input("\n是否先预览修改? (y/n, 默认y): ").strip().lower()
    dry_run = preview != 'n'
    
    if dry_run:
        print("\n--- 预览模式 ---")
        print("（将显示所有需要修改的文件，但不会实际修改）\n")
    else:
        print("\n--- 实际修改模式 ---")
        confirm = input("确认要修改所有文件吗? (yes/no): ").strip().lower()
        if confirm != 'yes':
            print("操作已取消")
            return
    
    # 执行替换
    replace_material_in_files(folder_path, dry_run=dry_run, file_extensions=file_extensions)

if __name__ == "__main__":
    main()