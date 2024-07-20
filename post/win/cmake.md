# 在windows使用cmake构建项目的一点感悟

## 
懒得讲背景这种东西了，直接说吧

## precompiled binary
如果是比较知名的开源项目，release里面有对比较常见平台(自然就包括windows)的预编译，我会优先考虑。写了`findxxx.cmake`最好，没写也算方便。相比于Linux，在windows使用cmake的一大痛点在于环境与路径，不过好在 cmake 有一个 `policy`，`CMP0074`允许我们设置`xxx_ROOt`来找到对应的库。比如这是`SDL2`的预编译文件
```
${env}/SDL2/2.30.0/-|
                    /cmake
                    /docs
                    /include
                    /lib
                    /README.txt
```
那么只需要在`find_package`前面加上`set(SDL2_ROOT "${env}/SDL2/2.30.0")`就好了。env是什么，是我预先设置好的 `set(env "C:/ProgramData/scoop/apps")`，出于方便把东西放在一起，并不是通过``scoop`下载的。有一个坏处是 `scoop install SDL2` 如果找不到默认会把原来的，也就是我手动放进去的也删除了，要注意备份。至于`target_link_libraries`的事情，一般搜一下`xxx cmake`，然后第一个`stack overflow`点进去就知道应该用什么名字::名字或者${变量}了

## FetchContent
使用`include(FetchContent)`引入，原理不明，大概会根据根目录下给出的构建描述生成.lib .dll文件，再手动处理一下`include`就好了。不过由于众所周知的原因，我更喜欢先把东西拉到本地，比起`GIT_REPOSITORY`和`URL`，显然`SOURCE_DIR`的生成速度更快

## header only
因为众所周知的原因，同样的实现 head only的库更加受到cpper们的喜爱。现在我用到的俩，一是`fmt`，在前面加上`#define FMT_HEADER_ONLY`就好，还有一个`utfcpp`，另外有一个C库名字和它很像，它俩在`debian`分别叫做`libutfcpp-dev` `libutf8.h-dev`，注意区分。

## gitsubmodules
比起 `FetchContent`,`gitsubmodules`可以更好的进行版本管理，不过我更喜欢手动把拉到本地来的东西标注好版本或者基于哪一次提交hash分开放，没怎么用过。pass

## 一些注意/技巧
* 使用`ninja`而不是`msbuild`
* `-DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=TRUE`，生成`compile_commands.json`
* 不用`include_directories`，使用`target_include_directories(xxx PRIVATE)`，不过由于`clangd`找不到标头，我还是加了一行`include_directories("D:\\Microsoft Visual Studio\\2022\\Professional\\VC\\Tools\\MSVC\\14.40.33807\\include")`
* 使用`visual studio`预先生成的`CMakePresets.json`，方便cmake找到工具链
* 使用`set_property`设置C++标准，`set(CMAKE_CXX_STANDARD xx)`在windows似乎不管用
* 使用`set(CMAKE_CXX_FLAGS_RELEASE "/xxx")`来设置不同情况的编译选项，对应的当然就是`CMAKE_CXX_FLAGS_DEBUG`。MSVC的命令行是用斜杠开头不是横杠
