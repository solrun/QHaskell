{-# OPTIONS_GHC -fno-warn-incomplete-patterns #-}
module QFeldspar.Expression.Conversions.Evaluation.GADTHigherOrder () where

import QFeldspar.MyPrelude
import QFeldspar.Expression.GADTHigherOrder
import qualified QFeldspar.Expression.GADTValue as FGV
import qualified QFeldspar.Type.GADT as TFG
import QFeldspar.Environment.Typed
import QFeldspar.Conversion
import QFeldspar.Variable.Conversion ()
import QFeldspar.Singleton
import QFeldspar.Expression.Utils.Common

instance (HasSin TFG.Typ t , t' ~ t) =>
         Cnv (Exp r t , Env FGV.Exp r) (FGV.Exp t') where
  cnv (ee , r) = let ?r = r in let t = sin :: TFG.Typ t in case ee of
    AryV _ _                 -> impossibleM
    LenV _                   -> impossibleM
    IndV _ _                 -> impossibleM
    Non                      -> impossibleM
    Som _                    -> impossibleM
    May _ _ _                -> impossibleM
    Mul _ _                  -> impossibleM
    Tmp _                    -> fail "Not Supported!"
    Let el eb                -> FGV.leT <$@> el <*@> eb
    _  -> $(biRecAppMQS 'ee ''Exp "FGV"
            ['AryV,'LenV,'IndV,'Non,'Som,'May,'Mul,'Let,'Tmp]
            (trvWrp 't))

instance (HasSin TFG.Typ ta , HasSin TFG.Typ tb , ta' ~ ta , tb' ~ tb) =>
         Cnv (Exp r ta -> Exp r tb , Env FGV.Exp r) (FGV.Exp (Arr ta' tb')) where
  cnv (f , r)  =  let ?r = r in
    pure (FGV.Exp ( FGV.getTrm
                  . frmRgt . cnvImp
                  . f
                  . frmRgt . cnvImp
                  . FGV.Exp ))

instance (HasSin TFG.Typ t , r ~ r' , t ~ t') =>
         Cnv (FGV.Exp t' , Env FGV.Exp r') (Exp r t)
         where
  cnv (FGV.Exp v , r) = let ?r = r in let t = sin :: TFG.Typ t in case t of
    TFG.Int                   -> pure (ConI v)
    TFG.Bol                   -> pure (ConB v)
    TFG.Flt                   -> pure (ConF v)
    TFG.Arr _ _               -> case TFG.getPrfHasSinArr t of
     (PrfHasSin , PrfHasSin)  -> Abs  <$@> samTyp t (FGV.Exp v)
    TFG.Tpl _ _               -> case TFG.getPrfHasSinTpl t of
     (PrfHasSin , PrfHasSin)  -> Tpl  <$@> FGV.Exp (fst v) <*@> FGV.Exp (snd v)
    TFG.Ary ta                -> case TFG.getPrfHasSinAry t of
      PrfHasSin
        | fst (bounds v) == 0 -> Ary  <$@> (FGV.Exp . (+ 1) . snd . bounds) v
                                      <*@> (samTyp (TFG.Arr TFG.Int ta)
                                            (FGV.Exp (fromJust
                                                    . flip lookup (assocs v))))
        | otherwise           -> fail "Bad Array!"
    TFG.Cmx                   -> Cmx <$@> FGV.Exp (realPart v)
                                     <*@> FGV.Exp (imagPart v)
    TFG.May _                 -> case TFG.getPrfHasSinMay t of
      PrfHasSin               -> case v of
                                   Nothing -> pure Non
                                   Just vv -> Som <$@> FGV.Exp vv
    TFG.Vct _                 -> impossible

instance (HasSin TFG.Typ ta , HasSin TFG.Typ tb , r ~ r' , ta ~ ta' , tb ~ tb')=>
         Cnv (FGV.Exp (Arr ta' tb') , Env FGV.Exp r') (Exp r ta -> Exp r tb)
         where
  cnv (FGV.Exp f , r) = let ?r = r in
    pure (frmRgt . cnvImp . FGV.mapTrm f . frmRgt . cnvImp)
