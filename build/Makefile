# 定义要处理的根目录和 head.txt 文件路径
DIRECTORY := ..
HEAD_FILE := ../head.txt

# 找出所有 .md 文件
MD_FILES := $(shell find $(DIRECTORY) -type f -name "*.md")

# 根据 .md 文件生成 .html 文件列表
HTML_FILES := $(patsubst %.md,%.html,$(MD_FILES))

# 默认目标，生成所有 .html 文件
all: $(HTML_FILES)

# 生成每个 .html 文件
%.html: %.md $(HEAD_FILE)
	@echo "Processing $< -> $@"; \
  title=$$(basename "$<"); \
  title=$${title%.md}; \
  sed "s/__enter_your_title_here__/$$title/g" $(HEAD_FILE) > $@; \
  pandoc $< >> $@

# 清理生成的 .html 文件
clean:
	rm -f $(HTML_FILES)

# 防止 Makefile 误解成文件名
.PHONY: all clean
