module QHaskell.Environment.Scoped(Env(Emp,Ext),len,get) where

import QHaskell.MyPrelude

import QHaskell.Variable.Scoped

import qualified QHaskell.Nat.ADT  as NA
import qualified QHaskell.Nat.GADT as NG

data Env :: NA.Nat -> * -> * where
  Emp :: Env NA.Zro t
  Ext :: t -> Env n t -> Env (NA.Suc n) t

deriving instance Eq   a => Eq   (Env n a)
deriving instance Show a => Show (Env n a)

instance Functor (Env n) where
  fmap      _ Emp       = Emp
  fmap     f (Ext x xs) = Ext (f x) (fmap f xs)

instance Foldable (Env n) where
  foldMap  _ Emp        = mempty
  foldMap  f (Ext x xs) = mappend (f x) (foldMap f xs)

instance Traversable (Env n) where
  traverse _ Emp        = pure Emp
  traverse f (Ext x xs) = Ext <$> f x <*> traverse f xs

len :: Env n a -> NG.Nat n
len Emp        = NG.Zro
len (Ext _ xs) = NG.Suc (len xs)

get :: Var n -> Env n t -> t
get Zro     (Ext x  _) = x
get (Suc n) (Ext _  r) = get n r
get _       _          = impossible