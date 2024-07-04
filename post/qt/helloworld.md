# qt & cmake & vscode & linux

install dependencies
```bash
sudo apt-get install libgl1-mesa-dev
sudo apt-get install qtbase5-dev qtchooser  qtbase5-dev-tools qt6-base-dev
sudo apt-get install qt5-xxx qt6-xxx libqt5-xxx libqt6-xxx
```

Then import qt library in CMakeLists.txt 
```cmake
find_package(Qt${QT_VERSION_MAJOR} COMPONENTS Core REQUIRED)
target_link_libraries(test Qt${QT_VERSION_MAJOR}::Core)
```

For other modules, see [qt5modules-doc](https://doc.qt.io/qt-5/qtmodules.html) or [qt6modules-doc](https://doc.qt.io/qt-6/qtmodules.html)

If you want to use qml, `apt list -a |grep qt |grep qml` may help

Here(Ubuntu22.04, default desktop) I cmd `unset GTK_PATH` to avoid a launch failure, I don't know what it will affect, but my desktop-gui works well still, maybe qt has some conflits with gtk.

Here is a example of CMakeLists.txt
```cmake
cmake_minimum_required(VERSION 3.8)

set(project_name test)
project(${project_name} LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

add_compile_options("-Wall" "-Wextra")
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_BUILD_TYPE Debug)

set(QT_VERSION_MAJOR 6)
find_package(QT NAMES Qt6 COMPONENTS Core Gui Widgets Qml Quick REQUIRED)
find_package(Qt${QT_VERSION_MAJOR} COMPONENTS Core REQUIRED)
find_package(Qt${QT_VERSION_MAJOR} COMPONENTS Gui REQUIRED)
find_package(Qt${QT_VERSION_MAJOR} COMPONENTS Widgets REQUIRED)
find_package(Qt${QT_VERSION_MAJOR} COMPONENTS Qml REQUIRED)
find_package(Qt${QT_VERSION_MAJOR} COMPONENTS Quick REQUIRED)

add_executable(${project_name}
  main.cpp
)
target_link_libraries(${project_name} Qt${QT_VERSION_MAJOR}::Core)
target_link_libraries(${project_name} Qt${QT_VERSION_MAJOR}::Gui)
target_link_libraries(${project_name} Qt${QT_VERSION_MAJOR}::Widgets)
target_link_libraries(${project_name} Qt${QT_VERSION_MAJOR}::Qml)
target_link_libraries(${project_name} Qt${QT_VERSION_MAJOR}::Quick)
```