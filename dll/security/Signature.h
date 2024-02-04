#pragma once

#include "windows.h"

#include <string>

#include <wincrypt.h>
#include <winefs.h>
#include <winscard.h>

#include "io/utils.h"
#include <intrin.h>

#include "exceptions/MessageException.h"

class SignatureVerificationException : public MessageException {
	using MessageException::MessageException;
};


class SignatureVerifier {

private:
	const char* pubKey = "-----BEGIN RSA PUBLIC KEY-----"
"MIICCgKCAgEAtYS43FjOHiK8tF+jMvc5CUcHplCrlSMsM+xcvFq/mnAdyXnOLOYw"
"QoF7eT/JzW0kDUbtQwCqQi2H+wPDE+A2UK31eKwAtoqExTx2wfUFTEzC/k+572X0"
"6utNzDIFLd0hWtLdw+QVj2E0GRLKdN7vUtCve5u1npGFMrYi+j0lw2y4Cb+v67dS"
"vrAG/QLMALzqV1SK9zVel3/kC6qUDZ0w3GWjLgs1wclfHPMF/OL8qO62x2bvoDHT"
"byZkYs0OMQF5wrYk4fwdfg5iDK7QAyTBB/O00/dwj1Th+lShOiLMB8CYXHf3maTU"
"4kxMcagxuEIiZTHQ44ewAXADQhyxxwTFLHEUQ2J4SJPkxjQGZQMlOqG2HIRlP1KG"
"xmHxzPMrlaL49B1PyBKSsleYTNnVb1Pc45y6uM5OagAGLF7MJ2xSgXKBINMIBYlG"
"Vjdd6kYLwQTgeCUqBMk/lteSFrOE5Y1BGSkgyDgXJHZnj/HTCf4Bq/BqP33pX1+d"
"nhQfTREY62Lsj+HkR5O94ObEAV0BNsncf38mvtCPrSTD0uvmw/Mt3sXnsd8Bks/k"
"6nW1LdUj91sU3Wp+YEJRAT+licJSxlXxIwOtt/4gxo2ZCenfUfTMqFJbjmnsVC75"
"Wi/igxc83NichuZ1g/ovLTY3yXL3gy9hn0pxPg7H8Rs1fw8WYqB1HM0CAwEAAQ=="
"-----END RSA PUBLIC KEY-----";

	SignatureVerifier() {

	}

public:
	static SignatureVerifier& getInstance()
	{
		static SignatureVerifier    instance; // Guaranteed to be destroyed.
							  // Instantiated on first use.
		return instance;
	}


	SignatureVerifier(SignatureVerifier const&) = delete;
	void operator=(SignatureVerifier const&) = delete;


	bool verify(unsigned char* data, int dataLen, unsigned char* signature, int signatureLen, std::string& error) {
		/***************************************************
		 * Import the public key and verify the signature
		 ***************************************************/

		DWORD dwBufferLen = 0, cbKeyBlob = 0, cbSignature = 0;
		LPBYTE pbBuffer = NULL, pbKeyBlob = NULL, pbSignature = NULL;
		HCRYPTPROV hProv = NULL;
		HCRYPTKEY hKey = NULL;
		HCRYPTHASH hHash = NULL;

		bool status = false;

		if (!CryptStringToBinaryA(pubKey, 0, CRYPT_STRING_BASE64HEADER, NULL, &dwBufferLen, NULL, NULL))
		{
			error = "Failed to convert BASE64 public key. Error 0x%.8X\n" + GetLastError();
			goto main_exit;
		}

		pbBuffer = (LPBYTE)LocalAlloc(0, dwBufferLen);
		if (pbBuffer == 0) {

			goto main_exit;
		}

		if (!CryptStringToBinaryA(pubKey, 0, CRYPT_STRING_BASE64HEADER, pbBuffer, &dwBufferLen, NULL, NULL))
		{
			error =  ("Failed to convert BASE64 public key. Error 0x%.8X\n" + GetLastError());
			goto main_exit;
		}

		if (!CryptDecodeObjectEx(X509_ASN_ENCODING | PKCS_7_ASN_ENCODING, RSA_CSP_PUBLICKEYBLOB, pbBuffer, dwBufferLen, 0, NULL, NULL, &cbKeyBlob))
		{
			error = ("Failed to parse public key. Error 0x%.8X\n" + GetLastError());
			goto main_exit;
		}

		pbKeyBlob = (LPBYTE)LocalAlloc(0, cbKeyBlob);
		if (pbKeyBlob == 0) {

			goto main_exit;
		}

		if (!CryptDecodeObjectEx(X509_ASN_ENCODING | PKCS_7_ASN_ENCODING, RSA_CSP_PUBLICKEYBLOB, pbBuffer, dwBufferLen, 0, NULL, pbKeyBlob, &cbKeyBlob))
		{
			error = ("Failed to parse public key. Error 0x%.8X\n" + GetLastError());
			goto main_exit;
		}

		if (!CryptAcquireContextA(&hProv, NULL, NULL, PROV_RSA_AES, CRYPT_VERIFYCONTEXT))
		{
			error = ("CryptAcquireContext failed with error 0x%.8X\n" + GetLastError());
			goto main_exit;
		}

		if (pbKeyBlob == 0) {

			goto main_exit;
		}
		if (!CryptImportKey(hProv, pbKeyBlob, cbKeyBlob, NULL, 0, &hKey))
		{
			error = ("CryptImportKey for public key failed with error 0x%.8X\n" + GetLastError());
			goto main_exit;
		}

		// Hash the data
		if (!CryptCreateHash(hProv, CALG_SHA_256, NULL, 0, &hHash))
		{
			error = ("CryptCreateHash failed with error 0x%.8X\n" + GetLastError());
			goto main_exit;
		}

		if (!CryptHashData(hHash, (LPCBYTE)data, dataLen, 0))
		{
			error = ("CryptHashData failed with error 0x%.8X\n" + GetLastError());
			goto main_exit;
		}

		// Sign the hash using our imported key
		if (!CryptVerifySignatureA(hHash, signature, signatureLen, hKey, NULL, 0))
		{
			error = ("Signature verification failed with error 0x%.8X\n" + GetLastError());
			goto main_exit;
		}

		error = ("Signature verified successfully!\n\n");
		status = true;

	main_exit:
		if (pbBuffer) LocalFree(pbBuffer);
		if (pbKeyBlob) LocalFree(pbKeyBlob);
		if (pbSignature) LocalFree(pbSignature);
		if (hHash) CryptDestroyHash(hHash);
		if (hKey) CryptDestroyKey(hKey);
		if (hProv) CryptReleaseContext(hProv, 0);

		return status;
	}
	
	bool verifyFile(std::filesystem::path path, std::filesystem::path sigPath, std::string& errorMsg) {
		if (!std::filesystem::is_regular_file(path)) {

			std::string error = "file does not exist: " + path.string();

			MessageBoxA(NULL, error.c_str(), "failure to verify file", MB_OK);

			// throw SignatureVerificationException(error);

			errorMsg = "failure to verify file: " + error;
			return false;
		}

		std::ifstream store_file_input(path.string(), std::ios::binary);

		std::vector<char> store_file_bytes(
			(std::istreambuf_iterator<char>(store_file_input)),
			(std::istreambuf_iterator<char>()));

		store_file_input.close();

		if (!std::filesystem::is_regular_file(sigPath)) {
			// throw SignatureVerificationException("signature not found: '" + sigPath + "'");
			std::string error = "signature not found: '" + sigPath.string() + "'";
			errorMsg = ("failure to verify file: " + error);
			return false;
		}

		std::ifstream signature_file_input(sigPath, std::ios::binary);

		std::string signature;

		signature_file_input >> signature;

		signature_file_input.close();

		size_t first_space = signature.find(' ');
		if (first_space != std::string::npos && first_space >= 0) {
			signature = signature.substr(0, first_space);
		}

		if (signature.size() != 1024) {
			// throw SignatureVerificationException("hash in '" + sigPath + " ' is not of the correct length: '" + std::to_string(signature.size()) + "'");
			std::string error = "hash in '" + sigPath.string() + " ' is not of the correct length: '" + std::to_string(signature.size()) + "'";
			errorMsg = ("failure to verify file: " + error);
			return false;
		}

		std::vector<unsigned char> signature_file_bytes = HexToBytes(signature);

		std::reverse(signature_file_bytes.begin(), signature_file_bytes.end());

		std::string error = "";
		if (!this->verify(
			(unsigned char*)store_file_bytes.data(),
			store_file_bytes.size(),
			(unsigned char*)signature_file_bytes.data(),
			signature_file_bytes.size(), error)) {

		/*	std::string msg = "failed to verify file signature:\n" + error;
			MessageBoxA(NULL, msg.c_str(), "failed to verify file signature", MB_OK);

			throw SignatureVerificationException(msg);*/

			errorMsg = "failed to verify file signature: " + error;
			return false;
		}

		return true;
	}
};
