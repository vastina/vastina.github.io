#!/bin/bash

# 定义要处理的根目录和 head.txt 文件路径
directory="."
head_filepath="head.txt"

# 检查 head.txt 是否存在
if [ ! -f "$head_filepath" ]; then
    echo "head.txt 文件未找到！"
    exit 1
fi

# 遍历指定目录及其子目录，找到所有 .md 文件
find "$directory" -type f -name "*.md" | while read -r md_filepath; do
    # 排除根目录下的 index.md
    if [ "$md_filepath" == "./index.md" ]; then
        continue
    fi

    # 定义对应的 .html 文件路径
    html_filepath="${md_filepath%.md}.html"

    # 将 head.txt 的内容复制到 .html 文件中
    cat "$head_filepath" > "$html_filepath"

    # 使用 pandoc 将 .md 文件转换为 .html 格式，并追加到 .html 文件中
    pandoc "$md_filepath" >> "$html_filepath" # -V title=$(basename "$md_filepath")

    filename=$(basename "$md_filepath")
    title="${filename%.md}"
    sed -i "s/__enter_your_title_here__/$title/g" "$html_filepath"

    echo "Processed: $md_filepath -> $html_filepath"
done
