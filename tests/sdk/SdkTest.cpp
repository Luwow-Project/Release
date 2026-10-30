// The test library: a bit of everything a library uses from the SDK, the Luau API from the executable,
// Userdata.h and the host's interface
#include "ILuauModule.h"
#include "ILuauHost.h"
#include "Userdata.h"
#include "lua.h"
#include "lualib.h"

#include <cmath>
#include <string>

namespace Luwow::SdkTest {
    using ILuauModule = Luwow::Engine::ILuauModule;
    using ILuauHost = Luwow::Engine::ILuauHost;

    static ILuauHost* testHost = nullptr;

    class Point {
    public:
        static constexpr const char* Name = "SdkTestPoint";

        Point(double x, double y) : x(x), y(y) {}

        int getX(lua_State* L) {
            lua_pushnumber(L, x);
            return 1;
        }

        int getY(lua_State* L) {
            lua_pushnumber(L, y);
            return 1;
        }

        int setX(lua_State* L) {
            x = luaL_checknumber(L, 3);
            return 0;
        }

        int length(lua_State* L) {
            lua_pushnumber(L, std::sqrt(x * x + y * y));
            return 1;
        }

    private:
        double x;
        double y;
    };

    // sdktest.answer() -> 42
    static int sdktest_answer(lua_State* L) {
        lua_pushinteger(L, 42);
        return 1;
    }

    // sdktest.abi() -> the module ABI it was built with
    static int sdktest_abi(lua_State* L) {
        lua_pushinteger(L, LUWOW_MODULE_ABI_VERSION);
        return 1;
    }

    // sdktest.point(x, y) -> a Point with X, Y and Length()
    static int sdktest_point(lua_State* L) {
        Luwow::Engine::Userdata<Point>::Push(L, luaL_checknumber(L, 1), luaL_checknumber(L, 2));
        return 1;
    }

    // sdktest.packageHas(path) -> whether the package being run has the file, through the host's package-read
    static int sdktest_packageHas(lua_State* L) {
        Luwow::Engine::Message read;
        read.topic = Luwow::Engine::Topics::PackageRead;
        read.data = luaL_checkstring(L, 1);
        lua_pushboolean(L, testHost->request(read) && read.result == 1);
        return 1;
    }

    static LuauExport exports[] = {
        { "answer", sdktest_answer },
        { "abi", sdktest_abi },
        { "point", sdktest_point },
        { "packageHas", sdktest_packageHas },
        { nullptr, nullptr }
    };

    class Library : public ILuauModule {
    public:
        ILuauModule* initialize(ILuauHost* host) override {
            testHost = host;
            Luwow::Engine::Userdata<Point>::Register(host->getMainState(), {
                { "Length", &Point::length },
            }, {
                { "X", &Point::getX, &Point::setX },
                { "Y", &Point::getY, nullptr },
            });
            return new Library();
        }

        Luwow::Engine::RunMode getRunMode() const override { return LUWOW_MODULE_RUN_MODE; }
        const char* getModuleName() const override { return "sdktest"; }
        const char* getModuleAlias() const override { return "Luwow"; }
        const LuauExport* getExports() const override { return exports; }
    };
} // namespace Luwow::SdkTest

LUWOW_REGISTER_MODULE(Luwow::SdkTest::Library)
