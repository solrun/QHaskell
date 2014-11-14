module QFeldspar.Expression.ADTValue
    (Exp(..)
    ,conI,conB,conF,var,abs,app,cnd,whl,tpl,fst,snd,ary,len,ind,leT
    ,cmx,typ
    ,Lft(..),CoLft(..),addV,add,mul) where

import QFeldspar.MyPrelude hiding (abs,fst,snd,may,som,non,cmx,tpl,cnd)
import qualified QFeldspar.Type.ADT as TFA
data Exp = ConI Int
         | ConB Bol
         | ConF Flt
         | Abs (Exp -> Exp)
         | Tpl (Exp , Exp)
         | Ary (Ary Exp)
         | Cmx Cmx

class Lft t where
  lft :: t -> Exp

instance Lft Int where
  lft = ConI

instance Lft Bool where
  lft = ConB

instance Lft Float where
  lft = ConF

instance (CoLft a , Lft b) => Lft (a -> b) where
  lft f = Abs (lft . f . colft)

instance (Lft a , Lft b) => Lft (a , b) where
  lft (x , y) = Tpl (lft x , lft y)

instance Lft a => Lft (Array Int a) where
  lft a = Ary (fmap lft a)

instance Lft (Complex Float) where
  lft = Cmx

class CoLft t where
  colft :: Exp -> t

instance CoLft Int where
  colft (ConI i) = i
  colft _        = badTypVal

instance CoLft Bool where
  colft (ConB b) = b
  colft _        = badTypVal

instance CoLft Float where
  colft (ConF f) = f
  colft _        = badTypVal

instance (Lft a , CoLft b) => CoLft (a -> b) where
  colft (Abs f) = colft . f . lft
  colft _       = badTypVal

instance (CoLft a , CoLft b) => CoLft (a , b) where
  colft (Tpl (x , y) ) = (colft x , colft y)
  colft _              = badTypVal

instance CoLft a => CoLft (Array Int a) where
  colft (Ary x) = fmap colft x
  colft _       = badTypVal

instance CoLft (Complex Float) where
  colft (Cmx c) = c
  colft _       = badTypVal

var :: a -> ErrM a
var = return

conI :: Int -> ErrM Exp
conI = return . ConI

conB :: Bool -> ErrM Exp
conB = return . ConB

conF :: Float -> ErrM Exp
conF = return . ConF

abs :: (Exp -> Exp) -> ErrM Exp
abs = return . Abs

app :: Exp -> Exp -> ErrM Exp
app (Abs vf) va = return (vf va)
app _        _  = fail "Type Error!"

addV :: Exp
addV = Abs (\ (ConI vl) -> Abs (\ (ConI vr) -> ConI (vl + vr)))

add :: Exp -> Exp -> Exp
add (ConI i) (ConI j) = ConI (i + j)
add _         _       = badTypVal

cnd :: Exp -> Exp -> Exp -> ErrM Exp
cnd (ConB vc) v1 v2 = return (if vc then v1 else v2)
cnd _         _  _  = badTypValM

whl :: Exp -> Exp -> Exp -> ErrM Exp
whl (Abs fc) (Abs fb) v = return (head (dropWhile
                            (\ x -> case fc x of
                                ConB b -> b
                                _      -> badTypVal)
                            (iterate fb v)))
whl _        _        _ = badTypValM

fst :: Exp -> ErrM Exp
fst (Tpl (vf , _ )) = return vf
fst _               = badTypValM

snd :: Exp -> ErrM Exp
snd (Tpl (_  , vs)) = return vs
snd _               = badTypValM

tpl :: Exp -> Exp -> ErrM Exp
tpl vf vs = return (Tpl (vf , vs))

ary :: Exp -> Exp -> ErrM Exp
ary (ConI l) (Abs vf) = return (Ary (listArray (0 , (l - 1))
                               [vf (ConI i)
                               | i <- [0 .. (l - 1)]]))
ary _        _        = badTypValM

len :: Exp -> ErrM Exp
len (Ary a) = (return . ConI . (1 +) . uncurry (flip (-)) . bounds) a
len _       = badTypValM

ind :: Exp -> Exp -> ErrM Exp
ind (Ary a) (ConI i) = return (a ! i)
ind _       _        = badTypValM

cmx :: Exp -> Exp -> ErrM Exp
cmx (ConF fr) (ConF fi) = return (Cmx (fr :+ fi))
cmx _         _         = badTypValM

leT :: Exp -> (Exp -> Exp) -> ErrM Exp
leT e f = return (f e)

typ :: TFA.Typ -> Exp -> ErrM Exp
typ _ = return

mul :: Exp -> Exp -> ErrM Exp
mul (ConI i) (ConI i') = return (ConI (i + i'))
mul (ConF f) (ConF f') = return (ConF (f + f'))
mul _        _         = badTypValM
