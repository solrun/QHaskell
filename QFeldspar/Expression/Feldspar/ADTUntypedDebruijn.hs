module QFeldspar.Expression.Feldspar.ADTUntypedDebruijn
    (Exp(..),fre) where

import QFeldspar.MyPrelude
import QFeldspar.Variable.Plain
import qualified QFeldspar.Type.Feldspar.ADT as TFA

data Exp = ConI Int
         | ConB Bool
         | ConF Float
         | Var  Var
         | Abs  Exp
         | App  Exp Exp
         | Cnd  Exp Exp Exp
         | Whl  Exp Exp Exp
         | Tpl  Exp Exp
         | Fst  Exp
         | Snd  Exp
         | Ary  Exp Exp
         | Len  Exp
         | Ind  Exp Exp
         | AryV Exp Exp
         | LenV Exp
         | IndV Exp Exp
         | Let  Exp Exp
         | Cmx  Exp Exp
         | Non
         | Som  Exp
         | May  Exp Exp Exp
         | Typ  TFA.Typ Exp

deriving instance Eq   Exp
deriving instance Show Exp

fre :: Exp -> [Nat]
fre ee = case ee of
  ConI _        -> []
  ConB _        -> []
  ConF _        -> []
  Var  n        -> [n]
  Abs  eb       -> freF eb
  App  ef ea    -> fre  ef ++ fre  ea
  Cnd  ec et ef -> fre  ec ++ fre  et ++ fre ef
  Whl  ec eb ei -> freF ec ++ freF eb ++ fre ei
  Tpl  ef es    -> fre  ef ++ fre es
  Fst  e        -> fre  e
  Snd  e        -> fre  e
  Ary  el ef    -> fre  el ++ freF ef
  Len  e        -> fre  e
  Ind  e  ei    -> fre  e  ++ fre ei
  AryV el ef    -> fre  el ++ freF ef
  LenV e        -> fre  e
  IndV e  ei    -> fre  e  ++ fre ei
  Let  el eb    -> fre  el ++ freF eb
  Cmx  er ei    -> fre  er ++ fre ei
  Non           -> []
  Som  e        -> fre  e
  May  em en es -> fre  em ++ fre en ++ freF es
  Typ  _  e     -> fre e

freF :: Exp -> [Nat]
freF f = drpZro (fre f)
  where
    drpZro = fmap prd . filter (/= Zro)
