from conan import ConanFile
from conan.tools.cmake import CMakeToolchain, CMake, cmake_layout


class JetsonAppRecipe(ConanFile):
    name = "jetson_app"
    version = "1.0"

    # Optional metadata
    license = "None"
    author = "lw liwang54321@gmail.com"
    url = "liwang54321@gmail.com"
    description = "Jetson App"
    topics = ("Jetson", "Xavier")

    # Binary configuration
    settings = "os", "compiler", "build_type", "arch"
    options = {"shared": [True, False], "fPIC": [True, False]}
    default_options = {"shared": True, "fPIC": True}

    # Sources are located in the same place as this recipe, copy them to the recipe
    # exports_sources = "CMakeLists.txt", "src/*", "include/*"

    def config_options(self):
        if self.settings.os == "Windows":
            del self.options.fPIC

    def layout(self):
        cmake_layout(self)

    def configure(self):
        self.options["*"].shared = True

        self.options["opencv"].with_gtk = False
        self.options["opencv"].with_jpeg = False
        self.options["opencv"].with_png = False
        self.options["opencv"].with_tiff = False
        self.options["opencv"].with_jpeg2000 = False
        self.options["opencv"].with_openexr = False
        self.options["opencv"].with_webp = False
        self.options["opencv"].with_msmf = False
        self.options["opencv"].with_msmf_dxva = False
        self.options["opencv"].with_quirc = False
        self.options["opencv"].with_ffmpeg = False
        self.options["opencv"].with_ade = False


    def requirements(self):
        self.requires("opencv/4.5.5")

    def generate(self):
        tc = CMakeToolchain(self)
        tc.generate()

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def package(self):
        cmake = CMake(self)
        cmake.install()

    def package_info(self):
        pass
        # self.cpp_info.libs = ["hello"]