#pragma once

#include <exception>

class MessageException : public std::exception {
private:
	std::string msg;
public:
	explicit MessageException(std::string msg) {
		this->msg = msg;
	}

	char* what() {
		return msg.data();
	}
};