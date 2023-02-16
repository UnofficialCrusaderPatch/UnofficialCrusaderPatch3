#pragma once

#include "framework.h"

#include <string>

#include <bcrypt.h>

#include "io/utils.h"
#include <intrin.h>

#define KEY_BIT_SIZE 4096
#define KEY_EXPONENT 65537

#pragma pack(1)
struct PubKey {
	BCRYPT_RSAKEY_BLOB header;
	unsigned int exponent = 0;
	unsigned char key[KEY_BIT_SIZE / 8];
};

class SignatureVerifier {

private:
	BCRYPT_ALG_HANDLE algHandle = NULL;
	BCRYPT_KEY_HANDLE keyHandle = NULL;
	PubKey pubKey;

public:
	SignatureVerifier(std::string publicKey) {
	
		std::vector<unsigned char> keyData = HexToBytes(publicKey);
		std::reverse(keyData.begin(), keyData.end());
	
		if (keyData.size() != (KEY_BIT_SIZE / 8)) {
			throw "invalid public key size";
		}
		
		NTSTATUS openStatus = BCryptOpenAlgorithmProvider(&this->algHandle, BCRYPT_RSA_ALGORITHM, MS_PRIMITIVE_PROVIDER, 0);
		if (openStatus != 0) {

			MessageBoxA(NULL, "bcrypt open error: " + openStatus, "bcrypt error", MB_OK);

			/*if (openStatus == STATUS_NOT_FOUND) {
				MessageBoxA(NULL, "not found", "bcrypt error", MB_OK);
			}

			if (openStatus == STATUS_INVALID_PARAMETER) {
				MessageBoxA(NULL, "invalid parameter", "bcrypt error", MB_OK);
			}

			if (openStatus == STATUS_NO_MEMORY) {
				MessageBoxA(NULL, "no memory", "bcrypt error", MB_OK);
			}*/

			return;
		}

		/**
		int structSize = sizeof(BCRYPT_RSAKEY_BLOB) + (keyData.size() + publicExponentData.size());
		BCRYPT_RSAKEY_BLOB* rsaKey = (BCRYPT_RSAKEY_BLOB*)calloc(1, structSize);
		if (rsaKey == NULL || rsaKey == 0) {
			MessageBoxA(NULL, "couldnt allocate struct", "bcrypt error", MB_OK);
			return;
		}
		rsaKey->Magic = BCRYPT_RSAPUBLIC_MAGIC;
		rsaKey->BitLength = 4096;
		rsaKey->cbPublicExp = publicExponentData.size();
		rsaKey->cbModulus = keyData.size();
		rsaKey->cbPrime1 = 0;
		rsaKey->cbPrime2 = 0;
		
		memcpy(rsaKey + sizeof(BCRYPT_RSAKEY_BLOB), publicExponentData.data(), publicExponentData.size()); // address to write the actual bytes to
		memcpy(rsaKey + sizeof(BCRYPT_RSAKEY_BLOB) + publicExponentData.size(), keyData.data(), keyData.size()); // address to write the actual bytes to  */

		this->pubKey.header.Magic = BCRYPT_RSAPUBLIC_MAGIC;
		this->pubKey.header.BitLength = KEY_BIT_SIZE;
		this->pubKey.header.cbPublicExp = sizeof(unsigned int);
		this->pubKey.header.cbModulus = keyData.size();
		this->pubKey.header.cbPrime1 = 0;
		this->pubKey.header.cbPrime2 = 0;
		this->pubKey.exponent = _byteswap_ulong(KEY_EXPONENT);
		memcpy(&this->pubKey.key, keyData.data(), keyData.size()); // address to write the actual bytes to

		NTSTATUS importStatus = BCryptImportKeyPair(this->algHandle, NULL, BCRYPT_RSAPUBLIC_BLOB, &this->keyHandle, (PUCHAR) &this->pubKey, sizeof(PubKey), BCRYPT_NO_KEY_VALIDATION);

		if (importStatus != 0) {

			MessageBoxA(NULL, "bcrypt import error: " + importStatus, "bcrypt error", MB_OK);

			/*if (importStatus == STATUS_INVALID_HANDLE) {
				MessageBoxA(NULL, "invalid handle", "bcrypt error", MB_OK);
			}

			if (importStatus == STATUS_INVALID_PARAMETER) {
				MessageBoxA(NULL, "invalid parameter", "bcrypt error", MB_OK);
			}

			if (importStatus == STATUS_NOT_SUPPORTED) {
				MessageBoxA(NULL, "not supported", "bcrypt error", MB_OK);
			}*/

			return;
		}

	}


	bool verify(std::string hash, std::string signedHash, std::string& error) {
		std::vector<unsigned char> hashBytes = HexToBytes(hash);
		std::vector<unsigned char> signedHashBytes = HexToBytes(signedHash);
		BCRYPT_PKCS1_PADDING_INFO padding;
		// padding.pszAlgId = BCRYPT_SHA256_ALGORITHM;
		padding.pszAlgId = NULL;
		NTSTATUS verifStatus = BCryptVerifySignature(keyHandle, (void*)&padding, hashBytes.data(), hashBytes.size(), signedHashBytes.data(), signedHashBytes.size(), BCRYPT_PAD_PKCS1);

		if (verifStatus == 0) {
			return true;
		}

		/*if (verifStatus == STATUS_INVALID_SIGNATURE) {
			error = "invalid signature";
			return false;
		}*/

		error = "error when verifying signature: " + verifStatus;
		return false;
	}
};
