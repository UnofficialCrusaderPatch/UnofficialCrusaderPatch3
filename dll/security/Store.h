#pragma once
#include "framework.h"
#include <string>

#include "security/Signature.h"

class Store {

private:
	std::string publicKey;
	SignatureVerifier* signatureVerifier;

public:

	Store(std::string publicKey) {
		this->publicKey = publicKey;

		//TODO: switch this on!
		this->signatureVerifier = new SignatureVerifier(publicKey);
		std::string error;
		// this->signatureVerifier->verify("ecf701f727d9e2d77c4aa49ac6fbbcc997278aca010bddeeb961c10cf54d435a", "a2c3bdfd4317acdfed5dfb7edcb31be2abeb9003105a8352fb3f22e4cb2df19586dc135e4a1fc6a32d926581164c5b2580dbb695e8aa657287a086b5a4e2b0392b60494ffca57cd00f5e274b7b7541cda7c1ed7f5fa3e96acf305b0175adf624b9b03b858a8c1a84b610bf92ff2da092127381e7206775deef7810b7d3ae69c6f222b0401502600a5f4340292710870f8b2e75039259176d959fd5a28f6337de3703c115e9f13193faaf6e7230659bec27dcf569cd2ebd8e26fa63a9d0a5be87567253ce7b823767ec7813bbea15eaf7f7e7b9f2dd29f24c527dfbd25f8829e7da6ea62fd73be9b94cc2cb167698f230c39f57783b2a72aec482d4cfe2a1100633aeb2302df66917dde53f6ac0436945df19b987826dfa1a94a6d925ce5dc0fef103f605322ac30e41eaad5388d9ecd6e4775262d4f05a458b76dc0301ddde86b4a324ff4913cdf4a46b478f5e7fea037f3c8e5339f7f7666160ec5f88163711cc7cec139c2048592dd3140513b58df3d5ec42a6d71c6bf0fa5c1e0d8a991c7c4a44b39ddc3fe62f9dab77b7135c1604b446cdcc5abea9ad3d91d172f6351da9648459b836ac5e406630f930de26e9f706b4d06b8e37aa967bfaa04c9a2630065f168f7159ec85753bcbcefa34641a5929f13da347cab1a2adb618b4e59325abf71b5ead0e22e6dc150fa70831b26c70dfd909c58240c20ffae7c9f50d5b4c7d", &error);
	}

	bool open(std::string storeFilePath, std::string signedHash) {
		return true;
	}

	bool verify(std::string extension, std::string hash) {
		return true;
	}

};
