module QFeldspar.Expression.Feldspar.GADTHigherOrder
    (Exp(..),sucAll,prdAll,mapVar,isFresh,absTmp,eql) where

import QFeldspar.MyPrelude

import QFeldspar.Variable.Typed

import qualified QFeldspar.Type.Feldspar.GADT as TFG
import QFeldspar.Singleton

data Exp :: [*] -> * -> * where
  ConI :: Int      -> Exp r Int
  ConB :: Bool     -> Exp r Bol
  ConF :: Float    -> Exp r Flt
  Var  :: Var r t  -> Exp r t
  Abs  :: (Exp r ta -> Exp r tb) -> Exp r (Arr ta tb)
  App  :: HasSin TFG.Typ ta =>
          Exp r (Arr ta tb) -> Exp r ta -> Exp r tb
  Cnd  :: Exp r Bol -> Exp r t -> Exp r t -> Exp r t
  Whl  :: (Exp r t -> Exp r Bol)-> (Exp r t -> Exp r t)
          -> Exp r t -> Exp r t
  Tpl  :: Exp r tf -> Exp r ts -> Exp r (Tpl tf ts)
  Fst  :: HasSin TFG.Typ ts => Exp r (Tpl tf ts) -> Exp r tf
  Snd  :: HasSin TFG.Typ tf => Exp r (Tpl tf ts) -> Exp r ts
  Ary  :: Exp r Int -> (Exp r Int -> Exp r ta) -> Exp r (Ary ta)
  Len  :: HasSin TFG.Typ ta => Exp r (Ary ta) -> Exp r Int
  Ind  :: Exp r (Ary ta) -> Exp r Int -> Exp r ta
  AryV :: Exp r Int -> (Exp r Int -> Exp r ta) -> Exp r (Vec ta)
  LenV :: HasSin TFG.Typ ta => Exp r (Vec ta) -> Exp r Int
  IndV :: Exp r (Vec ta) -> Exp r Int -> Exp r ta
  Let  :: HasSin TFG.Typ tl => Exp r tl -> (Exp r tl -> Exp r tb) -> Exp r tb
  Cmx  :: Exp r Flt -> Exp r Flt -> Exp r Cmx
  Tmp  :: String -> Exp r a
  Non  :: Exp r (May tl)
  Som  :: Exp r tl -> Exp r (May tl)
  May  :: HasSin TFG.Typ a =>
          Exp r (May a) -> Exp r b -> (Exp r a -> Exp r b) -> Exp r b

deriving instance Show (Exp r t)

instance Show (Exp r ta -> Exp r tb) where
  show f =
    let v = genNewNam "x"
        {-# NOINLINE v #-}
    in deepseq v $ ("(\\ "++ v ++ " -> (" ++
        show (f (Tmp v))
        ++ "))")

eql :: forall r t .  Exp r t -> Exp r t -> Bool
eql (ConI i)    (ConI i')     = i == i'
eql (ConB b)    (ConB b')     = b == b'
eql (ConF f)    (ConF f')     = f == f'
eql (Var  v)    (Var  v')     = v == v'
eql (Abs  f)    (Abs  f')     = eqlF f f'
eql (App ef (ea :: Exp r ta)) (App ef' (ea' :: Exp r ta')) =
  case eqlSin (sin :: TFG.Typ ta) (sin :: TFG.Typ ta') of
    Rgt Rfl -> eql ef ef' && eql ea ea'
    _       -> False
eql (Cnd ec et ef) (Cnd ec' et' ef') = eql ec ec' && eql et et' && eql ef ef'
eql (Whl ec eb ei) (Whl ec' eb' ei') = eqlF ec ec' && eqlF eb eb' && eql ei ei'
eql (Tpl ef es)    (Tpl ef' es')     = eql ef ef' && eql es es'
eql (Fst (e :: Exp r (Tpl t ts))) (Fst (e' :: Exp r (Tpl t ts'))) =
  case eqlSin (sin :: TFG.Typ ts) (sin :: TFG.Typ ts') of
    Rgt Rfl -> eql e e'
    _       -> False
eql (Snd (e :: Exp r (Tpl tf t))) (Snd (e' :: Exp r (Tpl tf' t))) =
  case eqlSin (sin :: TFG.Typ tf) (sin :: TFG.Typ tf') of
    Rgt Rfl -> eql e e'
    _       -> False
eql (Ary ei ef) (Ary ei' ef') = eql ei ei' && eqlF ef ef'
eql (Len (e :: Exp r (Ary ta))) (Len (e' :: Exp r (Ary ta'))) =
  case eqlSin (sin :: TFG.Typ ta) (sin :: TFG.Typ ta') of
    Rgt Rfl -> eql e e'
    _       -> False
eql (Ind (e :: Exp r (Ary t)) ei) (Ind (e' :: Exp r (Ary t)) ei') =
    eql e e' && eql ei ei'
eql (AryV ei ef) (AryV ei' ef') = eql ei ei' && eqlF ef ef'
eql (LenV (e :: Exp r (Vec ta))) (LenV (e' :: Exp r (Vec ta'))) =
  case eqlSin (sin :: TFG.Typ ta) (sin :: TFG.Typ ta') of
    Rgt Rfl -> eql e e'
    _       -> False
eql (IndV (e :: Exp r (Vec t)) ei) (IndV (e' :: Exp r (Vec t)) ei') =
    eql e e' && eql ei ei'
eql (Let (el :: Exp r ta) eb) (Let (el' :: Exp r ta') eb') =
  case eqlSin (sin :: TFG.Typ ta) (sin :: TFG.Typ ta') of
    Rgt Rfl -> eql el el' && eqlF eb eb'
    _       -> False
eql (Cmx ei er) (Cmx ei' er') = eql ei ei' && eql er er'
eql (Tmp x    ) (Tmp x')      = x == x'
eql Non         Non           = True
eql (Som e)     (Som e')      = eql e e'
eql (May (em  :: Exp r (May tm)) en  es)
    (May (em' :: Exp r (May tm')) en' es') =
  case eqlSin (sin :: TFG.Typ tm)(sin :: TFG.Typ tm') of
    Rgt Rfl -> eql em em' && eql en en' && eqlF es es'
    _       -> False
eql _           _             = False

eqlF :: forall r ta tb.  (Exp r ta -> Exp r tb) -> (Exp r ta -> Exp r tb) -> Bool
eqlF f f' = let v = genNewNam "__eqlFHO__"
                {-# NOINLINE v #-}
            in deepseq v $ eql (f (Tmp v)) (f' (Tmp v))

sucAll :: Exp r t' -> Exp (t ': r) t'
sucAll = mapVar Suc prd

prdAll :: Exp (t ': r) t' -> Exp r t'
prdAll = mapVar prd Suc

mapVar :: (forall t'. Var r  t' -> Var r' t') ->
          (forall t'. Var r' t' -> Var r  t') ->
          Exp r t -> Exp r' t
mapVar _ _ (ConI i)       = ConI i
mapVar _ _ (ConB b)       = ConB b
mapVar _ _ (ConF f)       = ConF f
mapVar f _ (Var v)        = Var (f v)
mapVar f g (Abs eb)       = Abs (mapVarF f g eb)
mapVar f g (App ef ea)    = App (mapVar f g ef) (mapVar f g ea)
mapVar f g (Cnd ec et ef) = Cnd (mapVar f g ec) (mapVar f g et) (mapVar f g ef)
mapVar f g (Whl ec eb ei) = Whl (mapVarF f g ec)
                                (mapVarF f g eb) (mapVar f g ei)
mapVar f g (Tpl ef es)    = Tpl (mapVar f g ef) (mapVar f g es)
mapVar f g (Fst e)        = Fst (mapVar f g e)
mapVar f g (Snd e)        = Snd (mapVar f g e)
mapVar f g (Ary el ef)    = Ary (mapVar f g el) (mapVarF f g ef)
mapVar f g (Len e)        = Len (mapVar f g e)
mapVar f g (Ind ea ei)    = Ind (mapVar f g ea) (mapVar f g ei)
mapVar f g (AryV el ef)   = AryV (mapVar f g el) (mapVarF f g ef)
mapVar f g (LenV e)       = LenV (mapVar f g e)
mapVar f g (IndV ea ei)   = IndV (mapVar f g ea) (mapVar f g ei)
mapVar f g (Let el eb)    = Let (mapVar f g el) (mapVarF f g eb)
mapVar f g (Cmx er ei)    = Cmx (mapVar f g er) (mapVar f g ei)
mapVar _ _ (Tmp x)        = Tmp x
mapVar _ _ Non            = Non
mapVar f g (Som e)        = Som (mapVar f g e)
mapVar f g (May em en es) = May (mapVar f g em) (mapVar f g en) (mapVarF f g es)

mapVarF :: (forall t'. Var r  t' -> Var r' t') ->
           (forall t'. Var r' t' -> Var r  t') ->
           (Exp r a -> Exp r b) -> (Exp r' a -> Exp r' b)
mapVarF f g ff = mapVar f g . ff . mapVar g f

absTmp :: forall r t t'. (HasSin TFG.Typ t', HasSin TFG.Typ t) =>
          Exp r t' -> String -> Exp r t -> Exp r t
absTmp xx s ee = let t = sin :: TFG.Typ t in case ee of
  ConI i                    -> ConI i
  ConB i                    -> ConB i
  ConF i                    -> ConF i
  Var v                     -> Var v
  Abs eb                    -> case TFG.getPrfHasSinArr t of
    (PrfHasSin , PrfHasSin) -> Abs (absTmp xx s . eb)
  App ef ea                 -> App (absTmp xx s ef)   (absTmp xx s ea)
  Cnd ec et ef              -> Cnd (absTmp xx s ec)   (absTmp xx s et)
                                    (absTmp xx s ef)
  Whl ec eb ei              -> Whl (absTmp xx s . ec) (absTmp xx s . eb)
                                   (absTmp xx s ei)
  Tpl ef es                 -> case TFG.getPrfHasSinTpl t of
    (PrfHasSin , PrfHasSin) -> Tpl (absTmp xx s ef)   (absTmp xx s es)
  Fst e                     -> Fst (absTmp xx s e)
  Snd e                     -> Snd (absTmp xx s e)
  Ary el ef                 -> case TFG.getPrfHasSinAry t of
    PrfHasSin               -> Ary (absTmp xx s el)   (absTmp xx s . ef)
  Len e                     -> Len (absTmp xx s e)
  Ind ea ei                 -> Ind (absTmp xx s ea)   (absTmp xx s ei)
  AryV el ef                -> case TFG.getPrfHasSinVec t of
    PrfHasSin               -> AryV (absTmp xx s el)   (absTmp xx s . ef)
  LenV e                    -> LenV (absTmp xx s e)
  IndV ea ei                -> IndV (absTmp xx s ea)   (absTmp xx s ei)
  Let el eb                 -> Let (absTmp xx s el)   (absTmp xx s . eb)
  Cmx er ei                 -> Cmx (absTmp xx s er)   (absTmp xx s ei)
  Tmp x
    | s == x                -> case eqlSin (sinTyp xx) t of
      Rgt Rfl               -> xx
      _                     -> ee
    | otherwise             -> ee
  Non                       -> Non
  Som e                     -> case TFG.getPrfHasSinMay t of
   PrfHasSin                -> Som (absTmp xx s e)
  May ec en es              -> May (absTmp xx s ec) (absTmp xx s en)
                                   (absTmp xx s . es)

-- when input string is not "__dummy__"
hasTmp :: String -> Exp r t -> Bool
hasTmp s ee = case ee of
  ConI _                    -> False
  ConB _                    -> False
  ConF _                    -> False
  Var  _                    -> False
  Abs eb                    -> hasTmpF s eb
  App ef ea                 -> hasTmp s ef || hasTmp s ea
  Cnd ec et ef              -> hasTmp s ec || hasTmp s et || hasTmp s ef
  Whl ec eb ei              -> hasTmpF s ec || hasTmpF s eb || hasTmp s ei
  Tpl ef es                 -> hasTmp s ef || hasTmp s es
  Fst e                     -> hasTmp s e
  Snd e                     -> hasTmp s e
  Ary el ef                 -> hasTmp s el || hasTmpF s ef
  Len e                     -> hasTmp s e
  Ind ea ei                 -> hasTmp s ea || hasTmp s ei
  AryV el ef                -> hasTmp s el || hasTmpF s ef
  LenV e                    -> hasTmp s e
  IndV ea ei                -> hasTmp s ea || hasTmp s ei
  Let el eb                 -> hasTmp s el || hasTmpF s eb
  Cmx er ei                 -> hasTmp s er || hasTmp s ei
  Tmp x
    | s == x                -> True
    | otherwise             -> False
  Non                       -> False
  Som e                     -> hasTmp s e
  May em en es              -> hasTmp s em || hasTmp s en || hasTmpF s es

hasTmpF :: String -> (Exp r ta -> Exp r tb) -> Bool
hasTmpF s f = hasTmp s (f (Tmp "__dummy__"))

isFresh :: (Exp r ta -> Exp r tb) -> Bool
isFresh f = not (hasTmp "__fresh__" (f (Tmp "__fresh__")))
