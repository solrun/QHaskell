module QFeldspar.Expression.GADTValue
    (Exp(..)
    ,conI,conB,conF,var,abs,app,cnd,whl,fst,snd,tpl,ary,len,ind,leT
    ,cmx,mul,tag
    ,getTrm,mapTrm) where

import QFeldspar.MyPrelude hiding (abs,fst,snd,may,som,non,cmx,tpl,cnd)
import qualified QFeldspar.MyPrelude as MP
import QFeldspar.Type.GADT ()

data Exp :: * -> * where
  Exp :: t -> Exp t

deriving instance Functor Exp

mapTrm :: (a -> b) -> Exp a -> Exp b
mapTrm = fmap

getTrm :: Exp t -> t
getTrm (Exp x) = x

var :: t -> t
var = id

conI :: Int -> Exp Int
conI = Exp

conB :: Bool -> Exp Bol
conB = Exp

conF :: Float -> Exp Flt
conF = Exp

abs :: Exp (Arr ta tb) -> Exp (Arr ta tb)
abs = id

app :: Exp (Arr ta tb) -> Exp ta -> Exp tb
app (Exp vf) (Exp va) = Exp (vf va)

cnd :: Exp Bol -> Exp a -> Exp a -> Exp a
cnd (Exp vc) (Exp vt) (Exp vf) = Exp (MP.cnd vc vt vf)

whl :: Exp (Arr s  Bol) -> Exp (Arr s s) -> Exp s -> Exp s
whl (Exp fc) (Exp fb) (Exp s) = Exp (MP.while fc fb s)

tpl :: Exp tf -> Exp ts -> Exp (Tpl tf ts)
tpl (Exp vf) (Exp vs) = Exp (MP.tpl vf vs)

fst :: Exp (Tpl a b) -> Exp a
fst (Exp v) = Exp (MP.fst v)

snd :: Exp (Tpl a b) -> Exp b
snd (Exp v) = Exp (MP.snd v)

ary :: Exp Int -> Exp (Arr Int a) -> Exp (Ary a)
ary (Exp vl) (Exp vf) = Exp (MP.arr vl vf)

len :: Exp (Ary a) -> Exp Int
len (Exp e)  = Exp (MP.arrLen e)

ind :: Exp (Ary a) -> Exp Int -> Exp a
ind (Exp v) (Exp vi) = Exp (MP.arrIx v vi)

leT :: Exp tl -> Exp (Arr tl tb) -> Exp tb
leT (Exp vl) (Exp vb) = Exp (vb vl)

cmx :: Exp Flt -> Exp Flt -> Exp Cmx
cmx (Exp fr) (Exp fi) = Exp (MP.cmx fr fi)

mul :: Num a => Exp a -> Exp a -> Exp a
mul (Exp i) (Exp i') = Exp (i + i')

tag :: String -> Exp a -> Exp a
tag _ = id
