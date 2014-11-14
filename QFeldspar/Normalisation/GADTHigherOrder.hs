module QFeldspar.Normalisation.GADTHigherOrder () where

import QFeldspar.MyPrelude

import QFeldspar.Expression.GADTHigherOrder
import QFeldspar.Expression.Utils.GADTHigherOrder(isFresh,absTmp)


import QFeldspar.Normalisation
import QFeldspar.Singleton
import qualified QFeldspar.Type.GADT as TFG

isVal :: Exp n t -> Bool
isVal ee = case ee of
    ConI _        -> True
    ConB _        -> True
    ConF _        -> True
    Var  _        -> True
    Abs  _        -> True
    App  _  _     -> False
    Cnd  _  _  _  -> False
    Whl  _  _  _  -> False
    Tpl  ef es    -> isVal ef && isVal es
    Fst  _        -> False
    Snd  _        -> False
    Ary  el  _    -> isVal el
    Len  _        -> False
    Ind  _  _     -> False
    AryV el  _    -> isVal el
    LenV  _       -> False
    IndV  _  _    -> False
    Let  _  _     -> False
    Cmx  _  _     -> True
    Tmp  _        -> True
    Non           -> True
    Som  e        -> isVal e
    May  _ _  _   -> False
    Mul _ _       -> False

val :: Exp n t -> (Bool,Exp n t)
val ee = (isVal ee , ee)

pattern V  v <- (val -> (True  , v))
pattern NV v <- (val -> (False , v))

instance HasSin TFG.Typ t => NrmOne (Exp n t) where
  nrmOne ee = let t = sin :: TFG.Typ t in case ee of
    ConI i                       -> pure (ConI i)
    ConB b                       -> pure (ConB b)
    ConF f                       -> pure (ConF f)
    Var x                        -> pure (Var  x)
    Abs eb                       -> case TFG.getPrfHasSinArr t of
      (PrfHasSin , PrfHasSin)    -> Abs  <$@> eb
    App ef             (NV ea)   -> chg (Let ea (\ x -> App ef     x ))
    App (Abs eb)       (V  ea)   -> chg (eb ea)
    App (Cnd (V ec) et ef)(V ea) -> chg (Cnd ec (App et ea) (App ef ea))
    App (Let (NV el) eb) (V ea)  -> chg (Let el (\ x -> App (eb x) ea))
    App ef             ea        -> App  <$@> ef <*@> ea

    Cnd (NV ec)      et ef       -> chg (Let ec (\ x -> Cnd x et ef))
    Cnd (ConB True)  et _        -> chg et
    Cnd (ConB False) _  ef       -> chg ef
    Cnd ec           et ef       -> Cnd  <$@> ec <*@> et <*@> ef

    Whl (NV ec) eb      ei       -> chg (Let ec (\ x -> Whl x  eb ei))
    Whl (V  ec) (NV eb) ei       -> chg (Let eb (\ x -> Whl ec x  ei))
    Whl (V  ec) (V  eb) (NV ei)  -> chg (Let ei (\ x -> Whl ec eb x))
    Whl ec eb ei                 -> Whl  <$@> ec <*@> eb <*@> ei

    Tpl (NV ef) es               -> case TFG.getPrfHasSinTpl t of
      (PrfHasSin , PrfHasSin)    -> chg (Let ef (\ x -> Tpl x es))
    Tpl (V ef)  (NV es)          -> case TFG.getPrfHasSinTpl t of
      (PrfHasSin , PrfHasSin)    -> chg (Let es (\ x -> Tpl ef x))
    Tpl ef      es               -> case TFG.getPrfHasSinTpl t of
      (PrfHasSin , PrfHasSin)    -> Tpl  <$@> ef <*@> es

    Fst (NV e)                   -> chg (Let e (\ x -> Fst x))
    Fst (Tpl (V ef) (V _))       -> chg  ef
    Fst e                        -> Fst  <$@> e

    Snd (NV e)                   -> chg (Let e (\ x -> Snd x))
    Snd (Tpl (V _)  (V es))      -> chg  es
    Snd e                        -> Snd  <$@> e

    Ary (NV el) ef               -> chg (Let el (\ x -> Ary x ef))
    Ary (V  el) (NV ef)          -> case TFG.getPrfHasSinAry t of
      PrfHasSin                  -> chg (Let ef (\ x -> Ary el x))
    Ary el      ef               -> case TFG.getPrfHasSinAry t of
      PrfHasSin                  -> Ary  <$@> el <*@> ef

    Len (NV ea)                  -> chg (Let ea (\ x -> Len x))
    Len (Ary (V el) _)           -> chg  el
    Len e                        -> Len  <$@> e

    Ind (NV ea)        ei        -> chg (Let ea (\ x -> Ind x  ei))
    Ind (V ea)         (NV ei)   -> chg (Let ei (\ x -> Ind ea x ))
    Ind (Ary (V _) ef) (V ei)    -> chg (App ef ei)
    Ind ea             ei        -> Ind  <$@> ea <*@> ei

    AryV (NV el) ef              -> chg (Let el (\ x -> AryV x ef))
    AryV (V  el) (NV ef)         -> case TFG.getPrfHasSinVec t of
      PrfHasSin                  -> chg (Let ef (\ x -> AryV el x))
    AryV el      ef              -> case TFG.getPrfHasSinVec t of
      PrfHasSin                  -> AryV  <$@> el <*@> ef

    LenV (NV ea)                  -> chg (Let ea (\ x -> LenV x))
    LenV (AryV (V el) _)          -> chg  el
    LenV e                        -> LenV  <$@> e

    IndV (NV ea)        ei        -> chg (Let ea (\ x -> IndV x  ei))
    IndV (V ea)         (NV ei)   -> chg (Let ei (\ x -> IndV ea x ))
    IndV (AryV (V _) ef) (V ei)   -> chg (App ef ei)
    IndV ea             ei        -> IndV  <$@> ea <*@> ei

    Cmx (NV er) ei               -> chg (Let er (\ x -> Cmx  x  ei))
    Cmx (V er)  (NV ei)          -> chg (Let ei (\ x -> Cmx  er x ))
    Cmx er ei                    -> Cmx  <$@> er <*@> ei

    Let (Let (NV el') eb')  eb   -> chg (Let el' (\ x -> Let (eb' x) eb))
    Let (Cnd ec et ef)      eb   -> chg (Cnd ec (Let et eb) (Let ef eb))
    Let (V v)               eb   -> chg (eb v)
    Let (NV v)         eb
      | isFresh eb               -> chg (eb v)
    Let el             eb        -> Let  <$@> el <*@> eb
    Tmp x                        -> pure (Tmp x)

    Non                          -> pure Non

    Som (NV e)                   -> case TFG.getPrfHasSinMay t of
      PrfHasSin                  -> chg (Let e  (\ x -> Som x))
    Som e                        -> case TFG.getPrfHasSinMay t of
      PrfHasSin                  -> Som  <$@> e

    May (NV em) en      es       -> chg (Let em (\ x -> May x  en es))
    May (V  em) (NV en) es       -> chg (Let en (\ x -> May em x  es))
    May (V  em) (V  en) (NV es)  -> chg (Let es (\ x -> May em en x ))
    May Non     en      _        -> chg en
    May (Som e) _       es       -> chg (App es e)
    May em      en      es       -> May  <$@> em <*@> en <*@> es

    Mul er  (NV ei)              -> chg (Let ei (\ x -> Mul  er x ))
    Mul (NV er) (V ei)           -> chg (Let er (\ x -> Mul  x  ei))
    Mul er ei                    -> Mul  <$@> er <*@> ei


instance (HasSin TFG.Typ tb, HasSin TFG.Typ ta) =>
         NrmOne (Exp n ta -> Exp n tb) where
  nrmOne f = let v = genNewNam "__NrmOneHO__"
                 {-# NOINLINE v #-}
             in deepseq v $ do eb <- nrmOne (f (Tmp v))
                               return (\ x -> absTmp x v eb)