# 图片二三事
大概是两个月前突然想研究一下图片格式问题，稍作记录，代码丢[github](https://github.com/vastina/img)上了

## bmp
主要参考了 [bmp.archive](https://web.archive.org/web/20080912171714/http://www.fortunecity.com/skyscraper/windows/364/bmpffrmt.html) 和 [这篇文章](https://zhuanlan.zhihu.com/p/698234015)，懒得讲

## png
.png 格式的图片整体分为三块(chunk)以及文件头，分别是 `IHDR`, `IDAT`, `IEND`，也就是 header, data, end。文件头格式是固定的，为八字节
```C++
constexpr char png_signature[8] = { 0x89, 'P', 'N', 'G', 0x0D, 0x0A, 0x1A, 0x0A };
```
后面的三块在结构上其实是相同的，如下(不清楚 32 位机器上如何，不讨论)
```
[数据区的长度，8字节][类型，4字节("IHDR/...")][数据区][前两个区的校验位，4字节]
```
#### 1. ihdr
ihdr的数据区是固定的，结构如下
```
[width][height][bit_depth][color_type][compression_method][filter_method][interlace_method]
```
其中长宽为4字节无符号整数，需要注意大小端序问题，可以用如下方法避免分支判断，其余各一字节，为配置，todo

#### 2. idat
idat的数据区格式和配置里面的 `bit_depth`,`color_type`,`compression_method` 有关系，每一行的开头会填入一字节来表示压缩方法，然后根据位宽的不同会有不同的格式，比如最常见的8位宽RGB_color_type:
```
[compression_method][[r][g][b]][[r][g][b]]...
...
```
至于要填入多少个单位的RGB，当然是看长宽

#### 3. iend的
iend数据区一般来说是留空的

#### 4. 校验位
关于校验位，直接调`zlib`就好了，任何一个合格的操作系统都应该提供

下面是一个简单的示例，生成一张 256*256 的纯蓝色png，编译的时候记得链接zlib，`-lz`就好
```C++
#include <fstream>
#include <cstdint>
#include <string>
#include <string_view>
#include <vector>
#include <zlib.h>

static inline uint32_t calculate_crc32( const std::vector<uint8_t>& data )
{
  return crc32( 0L, reinterpret_cast<const Bytef*>( data.data() ), data.size() );
}

static void write_uint32( std::ofstream& file, uint32_t value )
{
  file.put( ( value >> 24 ) & 0xFF );
  file.put( ( value >> 16 ) & 0xFF );
  file.put( ( value >> 8 ) & 0xFF );
  file.put( value & 0xFF );
}

void write_chunk( std::ofstream& file, const std::string_view& type, const std::vector<uint8_t>& data )
{
  write_uint32( file, data.size() );
  file.write( type.data(), 4 );
  file.write( reinterpret_cast<const char*>( data.data() ), data.size() );

  std::vector<uint8_t> crc_data( type.begin(), type.end() );
  // make copy here
  crc_data.insert( crc_data.end(), data.begin(), data.end() );

  uint32_t crc = calculate_crc32( crc_data );
  write_uint32( file, crc );
}

int main() {
  constexpr uint32_t width = 256, height = 256;
  std::ofstream fs( "blue.png", std::ios::binary | std::ios::app );
  {
    constexpr uint8_t png_signature[8] = { 0x89, 'P', 'N', 'G', 0x0D, 0x0A, 0x1A, 0x0A };
    fs.write( reinterpret_cast<const char*>( png_signature ), 8 );
  }
  {
    std::vector<uint8_t> ihdr( 13 );
    union {
      uint32_t val;
      uint8_t bytes[4];
    } u;
    u.val = width;
    ihdr[0] = u.bytes[3];
    ihdr[1] = u.bytes[2];
    ihdr[2] = u.bytes[1];
    ihdr[3] = u.bytes[0];
    u.val = height;
    ihdr[4] = u.bytes[3];
    ihdr[5] = u.bytes[2];
    ihdr[6] = u.bytes[1];
    ihdr[7] = u.bytes[0];
    ihdr[8] = 8; // bit_depth
    ihdr[9] = 2; // color_type rgb
    ihdr[10] = 0;// compression_method
    ihdr[11] = 0;// filter_method
    ihdr[12] = 0;// interlace_method
    write_chunk( fs, "IHDR", ihdr );
  }
  std::vector<uint8_t> data(width * height * 3 + height);
  {
    
    for ( unsigned y = 0; y < height; y++ )
      data[y * width * 3 + y] = 0;
    for ( unsigned y = 0; y < height; y++ )
      for( unsigned x = 0; x < width; x++ ){
        uint32_t index = ( y * width + x ) * 3 + y;
        data[index + 1] = 0;
        data[index + 2] = 0;
        data[index + 3] = 0xff;
    }
  }
  {
    std::vector<uint8_t> compressed_data( ::compressBound( data.size() ) + 4 );
    {
      constexpr char idat_signature[4] = { 'I', 'D', 'A', 'T' };
      compressed_data[0] = idat_signature[0];
      compressed_data[1] = idat_signature[1];
      compressed_data[2] = idat_signature[2];
      compressed_data[3] = idat_signature[3];
    }
    auto compressed_size { compressed_data.size() - 4 };
    ::compress( compressed_data.data() + 4, &compressed_size, data.data(), data.size() );
    compressed_data.resize( compressed_size + 4 );
    
    write_uint32( fs, compressed_size );
    fs.write( reinterpret_cast<const char*>( compressed_data.data() ), compressed_size + 4 );
    write_uint32( fs, calculate_crc32( compressed_data ) );
  }
  {
    write_chunk( fs, "IEND", {} );
  }
  fs.close();
  return 0;
}
```

## 关于最近的一些提交
最开始我想写一个 `HTML Parser`以及`MarkDown Parser`，但是感觉只写`Parser`有些不够，要不写个 `2d text render` 吧。不过由于我对图形学的完全不了解，怎么创建窗口，怎么加载字体，怎么将得到的文字纹理绘制在自己想画的地方，在不同的地方进行拉伸排版，font size 是什么单位，为什么不能和`window.width()`简单的相除得到一行可以放多少个字...... 因为图形学上有一堆问题不懂，最后在一次机缘巧合之下我发现可以将通过`freetype`加载的字体数据里的`buffer`按一定规律填入`vastina::png::png::data`，然后写入文件，就得到了文字的图片。虽然很简陋，但是`png::setIndex`至少可以直接画点。那下一步我再找些库把图片加载到窗口不就好了(虽然比直接操作窗口的绘制数据效率低了不少，多了两次io和编码解码)，然后就有了`testcase/png/window.cpp`。

这之后，我打算再学学，尝试写一些平台(windows, debian/ubuntu)无关向上层提供的渲染接口，把丑陋的生成再读取图片操作隔离在里面吧，或者学一点图形学也不是不可能(?) :)