#define YAML_CPP_STATIC_DEFINE
#include "yaml-cpp/yaml.h"

#include <filesystem>

#include <sstream>

#include <filesystem>
#include <fstream>

#include <exception>

#include "LuaYamlParser.h"

namespace LuaYamlParser {

	int parseScalarNode(lua_State* L, YAML::Node &node, std::string &errorMsg) {

		bool boolValue;
		int integerValue;
		double doubleValue;

		if (!YAML::convert<bool>::decode(node, boolValue)) {
			if (!YAML::convert<int>::decode(node, integerValue)) {
				if (!YAML::convert<double>::decode(node, doubleValue)) {
					// We tried all options, it must be a string
					lua_pushstring(L, node.Scalar().c_str());
				}
				else {
					lua_pushnumber(L, doubleValue);
				}
			}
			else {
				lua_pushinteger(L, integerValue);
			}
		}
		else {
			lua_pushboolean(L, boolValue);
		}

		return 1;
	}

	int parseTableNode(lua_State* L, YAML::Node& node, std::string& errorMsg) {
		int narr = 0;
		int nrec = 0;

		bool isMap = node.IsMap();
		bool isArray = node.IsSequence();

		if (isArray) {
			narr = node.size();
		}
		else if (isMap) {
			nrec = node.size();
		}
		else if (node.IsNull()) {
			// Return an empty table
		}
		else {
			std::stringstream output;
			output << "parse-lua: error at line " << node.Mark().line + 1 << ", column "
				<< node.Mark().column + 1 << ": " << "unsupported node type";
			errorMsg = output.str();
			return -1;
		}

		lua_createtable(L, narr, nrec);

		if (isMap) {

			for (YAML::const_iterator it = node.begin(); it != node.end(); ++it) {
				YAML::Node key = it->first;
				if (key.IsScalar()) {
					YAML::Node second = it->second;
					std::string k = key.as<std::string>();
					int code = -1;
					if (second.IsMap() || second.IsSequence()) {

						// Pushes a table unto the stack.
						code = LuaYamlParser::parseTableNode(L, second, errorMsg);
						
					}
					else if (second.IsScalar()) {

						// Pushes a value unto the stack.
						code = LuaYamlParser::parseScalarNode(L, second, errorMsg);
						
					}
					else if (second.IsNull()) {
						code = 1;
						lua_pushnil(L);
					}
					else {
						lua_pop(L, 1); // pop the created table
						std::stringstream output;
						output << "parse-lua: error at line " << node.Mark().line + 1 << ", column "
							<< node.Mark().column + 1 << ": " << "unsupported node type";
						errorMsg = output.str();
						return -1;
					}

					if (code == -1) {
						lua_pop(L, 1); // pop the created table
						return code;
					}

					// Does t[k] = v where arg 2 points to t on the stack
					// and v is at -1 on the stack.
					lua_setfield(L, -2, k.c_str());
				}
				else {
					lua_pop(L, 1); // pop the created table
					std::stringstream output;
					output << "parse-lua: error at line " << node.Mark().line + 1 << ", column "
						<< node.Mark().column + 1 << ": " << "key is not a scalar";
					errorMsg = output.str();
					return -1;
				}
			}

		}
		else  if (isArray) {
			// Note that lua arrays are 1-based
			for (std::size_t i = 0; i < node.size(); i++) {
				YAML::Node second = node[i];

				// Note that lua arrays are 1-based
				int key = i + 1;
				int code = -1;
				if (second.IsMap() || second.IsSequence()) {

					// Pushes a table unto the stack.
					code = LuaYamlParser::parseTableNode(L, second, errorMsg);

				}
				else if (second.IsScalar()) {
					// Pushes a value unto the stack.
					code = LuaYamlParser::parseScalarNode(L, second, errorMsg);
				}
				else {
					lua_pop(L, 1); // pop the created table
					std::stringstream output;
					output << "parse-lua: error at line " << node.Mark().line + 1 << ", column "
						<< node.Mark().column + 1 << ": " << "unsupported node type";
					errorMsg = output.str();
					return -1;
				}

				if (code == -1) {
					lua_pop(L, 1); // pop the created table
					return code;
				}

				// Does t[i] = v where arg 2 points to t on the stack
				// and v is at -1 on the stack.
				lua_seti(L, -2, key);
			}
		}

		return 1;

	}

	// TODO: try this instead of error throwing
	/*T t;
	if (convert<T>::decode(node, t))
		return t;*/
	int luaParseYamlContent(lua_State* L) {
		std::string fileContents = luaL_checkstring(L, 1);

		try {
			YAML::Node root = YAML::Load(fileContents);

			std::string errorMsg;
			int code = parseTableNode(L, root, errorMsg);

			if (code == -1) {
				return luaL_error(L, ("parsing yaml content failed: " + errorMsg).c_str());
			}

		}
		catch (YAML::ParserException pe) {
			return luaL_error(L, pe.what());
		}
		catch (std::exception e) {
			return luaL_error(L, e.what());
		}

		return 1;
	}

}