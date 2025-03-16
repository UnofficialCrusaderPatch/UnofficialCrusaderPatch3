#define YAML_CPP_STATIC_DEFINE
#include "yaml-cpp/yaml.h"

#include <filesystem>

#include <sstream>

#include <filesystem>
#include <fstream>

#include <exception>

#include "LuaYamlDumper.h"


namespace LuaYamlDumper {

    int dumpLuaScalar(lua_State* L, YAML::Node& node, std::string& errorMsg) {
        int type = lua_type(L, -1);

        if (type == LUA_TNUMBER) {
            // Integers are not really supported
            double rhs = static_cast<double>(lua_tonumber(L, -1));
            node = YAML::Node(rhs);
        }

        else if (type == LUA_TBOOLEAN) {
            bool rhs = lua_toboolean(L, -1);
            node = YAML::Node(rhs);
        }
        else if (type == LUA_TSTRING) {
            std::string rhs = lua_tostring(L, -1);
            node = YAML::Node(rhs);
        }
        else if (type == LUA_TNIL) {
            node = YAML::Null; // TODO: empty string is the name as null?
        }
        else {
            std::stringstream output;
            output << "generate-lua: error at line " << node.Mark().line + 1 << ", column "
                << node.Mark().column + 1 << ": " << "unsupported type: " << type;
            errorMsg = output.str();

            return -1;
        }

        return 0;
    }

    // TODO: should this function pop the given table, or not? I guess not
    int dumpLuaTable(lua_State* L, YAML::Node& node, std::string& errorMsg) {

        bool isFirst = true;
        int tableKeyType = 0;
        int previousKey = 0;

        /* table is in the stack at index 't' */
        lua_pushnil(L);  /* first key */

        /* -2 is because the table was given in this function */
        while (lua_next(L, -2) != 0) {

            int keyType = lua_type(L, -2);
            int valueType = lua_type(L, -1);

            // We check if any next key type is the same as the first key type
            // Because lua supports tables with integer and string keys, but yaml would convert them to strings
            // This has implications so let's throw errors!
            if (isFirst) {
                isFirst = false;
                tableKeyType = keyType;
            }
            else {
                if (tableKeyType != keyType) {

                    // Remove value & key
                    lua_pop(L, 2);

                    std::stringstream output;
                    output << "generate-lua: error at line " << node.Mark().line + 1 << ", column "
                        << node.Mark().column + 1 << ": " << "node keys need to be an array index (integer) or string";
                    errorMsg = output.str();

                    return -1;
                }
            }

            YAML::Node value;

            if (valueType == LUA_TTABLE) {
                if (dumpLuaTable(L, value, errorMsg) == -1) {
                    // Remove value & key
                    lua_pop(L, 2);
                    return -1;
                }
            }
            else {
                if (dumpLuaScalar(L, value, errorMsg) == -1) {
                    // Remove value & key
                    lua_pop(L, 2);
                    return -1;
                }
            }

            if (keyType == LUA_TSTRING) {
                // Map
                std::string key = lua_tostring(L, -2);
                node[key] = value;
            }
            else if (keyType == LUA_TNUMBER) {
                // Sequence

                int isnum;
                int key = lua_tointegerx(L, -2, &isnum);

                if (isnum == 0) {
                    // Remove value & key
                    lua_pop(L, 2);

                    std::stringstream output;
                    output << "generate-lua: error at line " << node.Mark().line + 1 << ", column "
                        << node.Mark().column + 1 << ": " << "node keys need to be an array index (integer) or string";
                    errorMsg = output.str();

                    return -1;
                }

                if (previousKey + 1 != key) {
                    // Remove value & key
                    lua_pop(L, 2);

                    std::stringstream output;
                    output << "generate-lua: error at line " << node.Mark().line + 1 << ", column "
                        << node.Mark().column + 1 << ": " << "table does not have consecutive keys " << key;
                    errorMsg = output.str();

                    return -1;
                }

                previousKey = key;

                // Lua is 1-based
                node[key-1] = value;
            }
            else {
                // Remove value & key
                lua_pop(L, 2);

                std::stringstream output;
                output << "generate-lua: error at line " << node.Mark().line + 1 << ", column "
                    << node.Mark().column + 1 << ": " << "unknown key type: " << keyType;
                errorMsg = output.str();

                return -1;
            }

            ///* uses 'key' (at index -2) and 'value' (at index -1) */
            //printf("%s - %s\n",
            //    lua_typename(L, lua_type(L, -2)),
            //    lua_typename(L, lua_type(L, -1)));
            /* removes 'value'; keeps 'key' for next iteration */
            lua_pop(L, 1);
        }

        return 0;
    }

    int luaDumpLuaTable(lua_State* L) {
        luaL_checktype(L, 1, LUA_TTABLE);

        YAML::Node root;
        std::string errorMsg;

        try {
            int code = dumpLuaTable(L, root, errorMsg);

            if (code == -1) {
                return luaL_error(L, errorMsg.c_str());
            }

            std::string output = YAML::Dump(root);

            lua_pushstring(L, output.c_str());
        }
        catch (std::exception e) {
            return luaL_error(L, e.what());
        }

        return 1;
    }


}