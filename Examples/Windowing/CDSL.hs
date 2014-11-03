module Examples.Windowing.CDSL where

import QFeldspar.CDSL

windowingVec :: Vec (Data Cmx) -> Vec (Data Cmx)
windowingVec = \ s -> let ls = shared (len s) in
                      zipWith mul
                       (append
                        (replicate (sub ls (div ls 4)) (cmx 1.0 0.0))
                        (replicate ls                  (cmx 0.0 0.0)))
                       s

windowing :: Data (Ary Cmx) -> Data (Ary Cmx)
windowing = toExpF windowingVec