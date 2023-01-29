#pragma once

#include "framework.h"

#include <bcrypt.h>

#include <sstream>


#define NT_SUCCESS(Status)          (((NTSTATUS)(Status)) >= 0)

#define STATUS_UNSUCCESSFUL         ((NTSTATUS)0xC0000001L)

class Hasher
{

public:
	static Hasher& getInstance()
	{
		static Hasher    instance; // Guaranteed to be destroyed.
							  // Instantiated on first use.
		return instance;
	}


	Hasher(Hasher const&) = delete;
	void operator=(Hasher const&) = delete;

	/** If we need a destructor, put this there:
	* 
	if (hAlg)
	{
		BCryptCloseAlgorithmProvider(hAlg, 0);
	}

	if (hHash)
	{
		BCryptDestroyHash(hHash);
	}

	if (pbHashObject)
	{
		HeapFree(GetProcessHeap(), 0, pbHashObject);
	}

	if (pbHash)
	{
		HeapFree(GetProcessHeap(), 0, pbHash);
	}

	 */

private:

	BCRYPT_ALG_HANDLE       hAlg = NULL;
	BCRYPT_HASH_HANDLE      hHash = NULL;
	NTSTATUS                status = STATUS_UNSUCCESSFUL;
	DWORD                   cbData = 0,
		cbHash = 0,
		cbHashObject = 0;
	PBYTE                   pbHashObject = NULL;
	PBYTE                   pbHash = NULL;

	Hasher() {



		char msg[301];

		//open an algorithm handle
		if (!NT_SUCCESS(status = BCryptOpenAlgorithmProvider(
			&hAlg,
			BCRYPT_SHA256_ALGORITHM,
			NULL,
			0)))
		{
			snprintf(msg, 300, "**** Error 0x%x returned by BCryptOpenAlgorithmProvider\n", status); MessageBoxA(NULL, msg, "hash error", MB_OK);
			throw msg;
			//goto Cleanup;
		}

		//calculate the size of the buffer to hold the hash object
		if (!NT_SUCCESS(status = BCryptGetProperty(
			hAlg,
			BCRYPT_OBJECT_LENGTH,
			(PBYTE)&cbHashObject,
			sizeof(DWORD),
			&cbData,
			0)))
		{
			snprintf(msg, 300, "**** Error 0x%x returned by BCryptGetProperty\n", status); MessageBoxA(NULL, msg, "hash error", MB_OK);
			throw msg;
			//goto Cleanup;
		}

		//allocate the hash object on the heap
		pbHashObject = (PBYTE)HeapAlloc(GetProcessHeap(), 0, cbHashObject);
		if (NULL == pbHashObject)
		{
			snprintf(msg, 300, "**** memory allocation failed\n"); MessageBoxA(NULL, msg, "hash error", MB_OK);
			throw msg;
			//goto Cleanup;
		}

		//calculate the length of the hash
		if (!NT_SUCCESS(status = BCryptGetProperty(
			hAlg,
			BCRYPT_HASH_LENGTH,
			(PBYTE)&cbHash,
			sizeof(DWORD),
			&cbData,
			0)))
		{
			snprintf(msg, 300, "**** Error 0x%x returned by BCryptGetProperty\n", status); MessageBoxA(NULL, msg, "hash error", MB_OK);
			throw msg;
			//goto Cleanup;
		}

		//allocate the hash buffer on the heap
		pbHash = (PBYTE)HeapAlloc(GetProcessHeap(), 0, cbHash);
		if (NULL == pbHash)
		{
			snprintf(msg, 300, "**** memory allocation failed\n"); MessageBoxA(NULL, msg, "hash error", MB_OK);
			throw msg;
			//goto Cleanup;
		}
	
	};

public:

	bool hash(char* data, size_t size, std::string& hash, std::string& errorMsg) {

		char msg[301];

		//create a hash
		if (!NT_SUCCESS(status = BCryptCreateHash(
			hAlg,
			&hHash,
			pbHashObject,
			cbHashObject,
			NULL,
			0,
			0)))
		{
			snprintf(msg, 300, "**** Error 0x%x returned by BCryptCreateHash\n", status); MessageBoxA(NULL, msg, "hash error", MB_OK);
			errorMsg = msg;
			return false;
		}


		//hash some data
		if (!NT_SUCCESS(status = BCryptHashData(
			hHash,
			(PBYTE)data,
			size,
			0)))
		{
			snprintf(msg, 300, "**** Error 0x%x returned by BCryptHashData\n", status); MessageBoxA(NULL, msg, "hash error", MB_OK);
			errorMsg = msg;
			return false;
		}

		//close the hash
		if (!NT_SUCCESS(status = BCryptFinishHash(
			hHash,
			pbHash,
			cbHash,
			0)))
		{
			snprintf(msg, 300, "**** Error 0x%x returned by BCryptFinishHash\n", status); MessageBoxA(NULL, msg, "hash error", MB_OK);
			errorMsg = msg;
			return false;
		}



		static const char characters[] = "0123456789ABCDEF";

		// Zeroes out the buffer unnecessarily, can't be avoided for std::string.
		std::string ret(cbHash * 2, 0);

		// Hack... Against the rules but avoids copying the whole buffer.
		auto buf = const_cast<char*>(ret.data());


		for (int i = 0; i < cbHash; i++)
		{
			*buf++ = characters[pbHash[i] >> 4];
			*buf++ = characters[pbHash[i] & 0x0F];
		}

		hash = ret;


		return true;

	}
};