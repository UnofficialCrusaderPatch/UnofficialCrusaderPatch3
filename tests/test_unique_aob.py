"""Exercise the real framework cache, scanner facade and capture decoder."""
from pathlib import Path
import unittest
from lupa.lua54 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]


class UniqueAOBTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.globals().root = (ROOT / 'content/ucp/code').as_posix()
        self.lua.execute('''
          package.path=root..'/?.lua;'..package.path
          log=function() end
          local matches={}
          memoryReads,cacheScans,codeScans=0,0,0
          codeFirst,codeSecond=4198400,nil
          ucp={internal={scanForAOB=function(pattern,start,stop)
            cacheScans=cacheScans+1
            for _,address in ipairs(matches) do
              if address>=start and address<=stop then return address end
            end
          end,scanForAOBInMainModule=function(pattern)
            codeScans=codeScans+1; normalized=pattern
            return codeFirst,codeSecond
          end,readInteger=function(address)
            memoryReads=memoryReads+1;return address==4198401 and 16 or 77
          end,readBytes=function(address,count)
            memoryReads=memoryReads+1;return {170,187}
          end}}
          core=require('core')
          utils=require('utils')
          data={cache=require('data/cache')}
          function seed(pattern,candidate,processMatches)
            matches=processMatches
            local original=io.open
            io.open=function() return {read=function() return '' end,close=function() end} end
            yaml={parse=function() return {[pattern]=candidate} end}
            data.cache.AOB.loadFromFile()
            io.open=original
          end
          function rejects(fragment,fn)
            local ok,err=pcall(fn)
            assert(not ok and tostring(err):find(fragment,1,true),tostring(err))
            assert(memoryReads==0,'must reject before reading operands')
          end
        ''')

    def test_cold_and_warm_cache_both_check_uniqueness(self):
        self.lua.execute('''
          seed('AA BB',nil,{4198400})
          assert(core.AOBScanUnique('AA BB','camera')==4198400)
          assert(core.AOBScanUnique('AA BB','camera')==4198400)
          assert(codeScans==2 and cacheScans==0)
          assert(core.AOBScan('AA BB')==4198400 and cacheScans==1)
        ''')

    def test_cached_first_or_later_duplicate_is_rejected(self):
        for cached in (4198400, 4199304):
            with self.subTest(cached=cached):
                self.lua.globals().cached = cached
                self.lua.execute('''
                  seed('AA BB',cached,{4198400,4199304})
                  codeSecond=4199304
                  rejects('Ambiguous executable AOB for camera: 0x401000 and 0x401388',function()
                    core.AOBScanUnique('AA BB','camera') end)
                  assert(core.AOBScan('AA BB')==cached,'failure changed cache')
                ''')

    def test_missing_code_does_not_search_entire_process(self):
        self.lua.execute('''
          seed('AA BB',4203304,{4203304});codeFirst=nil
          rejects('Executable AOB not found for input-frame',function()
            core.AOBScanUnique('AA BB','input-frame') end)
          assert(cacheScans==0)
        ''')

    def test_cached_non_code_match_is_replaced_by_verified_code(self):
        self.lua.execute('''
          seed('AA BB',4203304,{4198400,4203304})
          assert(core.AOBScanUnique('AA BB','camera')==4198400)
          assert(cacheScans==0)
          assert(core.AOBScan('AA BB')==4198400 and cacheScans==1)
        ''')

    def test_changed_cache_is_replaced_only_after_verification(self):
        self.lua.execute('''
          seed('AA BB',4197304,{4198400})
          assert(core.AOBScanUnique('AA BB','camera')==4198400)
          assert(cacheScans==0)
          assert(core.AOBScan('AA BB')==4198400 and cacheScans==1)
        ''')

    def test_unique_capture_keeps_existing_decoder_and_result_shape(self):
        self.lua.execute('''
          local pattern='E8 ? ? ? ? ? ? ? ? AA BB'
          seed(pattern,4198400,{4198400})
          local at,relative,integer,bytes=utils.AOBExtractUnique(
            '@(E8 ? ? ? ?) I(? ? ? ?) (AA BB)','action')
          assert(normalized==pattern)
          assert(at==4198400 and relative==4198421 and integer==77 and bytes[1]==170 and bytes[2]==187)
          local packed=utils.AOBExtractUnique('@(E8 ? ? ? ?) I(? ? ? ?) (AA BB)','action',false)
          assert(packed[1]==at and packed[2][1]==relative and packed[2][2]==integer)
          local old=utils.AOBExtract('@(E8 ? ? ? ?) I(? ? ? ?) (AA BB)',nil,nil,false)
          assert(old[1]==at and old[2][1]==relative and codeScans==2)
        ''')

    def test_ambiguous_capture_never_decodes_operand(self):
        self.lua.execute('''
          seed('E8 ? ? ? ?',4199304,{4198400,4199304});codeSecond=4199304
          rejects('Ambiguous executable AOB for action',function()
            utils.AOBExtractUnique('@(E8 ? ? ? ?)','action') end)
        ''')


if __name__ == '__main__':
    unittest.main()
