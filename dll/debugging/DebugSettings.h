#pragma once

namespace debugging {
	class DebugSettings {
	public:
		static DebugSettings& getInstance()
		{
			static DebugSettings    instance; // Guaranteed to be destroyed.
			// Instantiated on first use.
			return instance;
		}

		DebugSettings(DebugSettings const&) = delete;
		void operator=(DebugSettings const&) = delete;

		bool aggressiveGC = false;
	private:
		DebugSettings() {

		}
	};
}
