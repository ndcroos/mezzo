
-----------------------------------------------------------------------------
-- |
-- Module      :  Mezzo.Compose.Builder
-- Description :  Music builder
-- Copyright   :  (c) Dima Szamozvancev
-- License     :  MIT
--
-- Maintainer  :  ds709@cam.ac.uk
-- Stability   :  experimental
-- Portability :  portable
--
-- Pattern of combinatorially building musical terms of various types.
--
-----------------------------------------------------------------------------

module Mezzo.Compose.Builder
    (
    -- * General builder types
      Spec
    , Conv
    , Mut
    , Term
    , AConv
    , AMut
    , ATerm
    , Mut'
    , spec
    , constConv
    -- * Music-specific builder types
    , RootS
    , RestS
    , ChorS
    , RootM
    , ChorM
    , ChorC
    , ChorC'
    , RootT
    , RestT
    , ChorT
    )
    where

import Mezzo.Model

import GHC.TypeLits

-------------------------------------------------------------------------------
-- General types
-------------------------------------------------------------------------------

-- | Specifier: specifies a value of some type which starts the building.
type Spec t = forall m. (t -> m) -> m

-- | Converter: converts a value of type s to a value of type t.
type Conv s t = s -> Spec t

-- | Mutator: mutates a value of type t.
type Mut t = Conv t t

-- | Terminator: finishes building a value of type t and returns a result of type r.
type Term t r = t -> r

-- | Converter with argument: converts a value of type s to a value of type t, consuming an argument of type a.
type AConv a s t = s -> a -> Spec t

-- | Mutator with argument: mutates a value of type t, consuming an argument of type a.
type AMut a t = AConv a t t

-- | Terminator with argument: finishes building a value of type t, returning a result of
-- type r, consuming an argument of type a.
type ATerm a t r = t -> a -> r

-- | Flexible mutator: mutator that allows slight changes in the type (otherwise use 'Conv').
type Mut' t t' = Conv t t'

-- | Returns a new specifier for the given value.
spec :: t -> Spec t
spec i c = c i

-- | A converter that ignores its argument and returns the given constant value.
constConv :: t -> Conv s t
constConv = const . spec

-- | A mutator that does nothing.
nop :: Mut t
nop = spec

-------------------------------------------------------------------------------
-- Music specific types
-------------------------------------------------------------------------------

-- | Root specifier.
type RootS r = Primitive r => Spec (Root r)

-- | Rest specifier.
type RestS = Spec (Pit Silence)

-- | Chord specifier.
type ChorS c = Primitive c => Spec (Cho c)

-- | Root mutator.
type RootM r r' = (Primitive r, Primitive r') => Mut' (Root r) (Root r')

-- | Chord mutator.
type ChorM c c' = (Primitive c, Primitive c') => Mut' (Cho c) (Cho c')

-- | Converter from roots to chords.
type ChorC' c r t i = (Primitive r, Primitive t, Primitive i) => AConv (Inv i) (Root r) (Cho (c r t i))

-- | Converter from roots to chords, using the default inversion.
type ChorC c r t = (Primitive r, Primitive t) => Conv (Root r) (Cho (c r t Inv0))

-- | Note terminator.
type RootT s r d = Primitive r => Term (Root r) (Music s (FromRoot r d))

--  | Rest terminator.
type RestT s d = Term (Pit Silence) (Music s (FromSilence d))

-- | Chord terminator.
type ChorT s c d = Primitive c => Term (Cho c) (Music s (FromChord c d))

-- inKey :: KeyS key -> a -> a
-- inKey key cont = let ?k = key in cont
--
--
-- i :: (?k :: KeyS key) => RootS (DegreeRoot key I)
-- i = spec Root
--
-- c :: RootS (PitchRoot (Pitch C Natural Oct3))
-- c = spec Root
--
-- sharp :: RootM r (Sharpen r)
-- sharp = constConv Root
--
-- maj :: ChorC Triad r MajTriad
-- maj = constConv Cho
--
-- qn :: RootT r 8
-- qn p = Note p Dur
--
-- qc :: KnownNat n => ChorT (c :: ChordType n) 8
-- qc c = Chord c Dur


-------------------------------------------------------------------------------
-- Silly examples
-- Most of these are quite pointless, but show that the pattern enables us to
-- write DSLs with a very fluent feel.
-------------------------------------------------------------------------------

inc :: Mut Int
inc i = spec (succ i)

toString :: Conv Int String
toString n = spec (show n)

ex :: Mut String
ex s = spec (s ++ "!")

smile :: Term String String
smile s = s ++ " :)"

say :: String -> Spec String
say = spec

add :: Int -> Spec Int
add = spec

and' :: Mut t
and' = nop

to :: Int -> Mut Int
to y x = spec (x + y)

display :: Conv Int String
display = spec . show

result :: Term String String
result = ("result: " ++)

compute :: Double -> Spec Double
compute = spec

plus :: AMut Double Double
plus i p = spec (i + p)

please :: Term Double Double
please = id

percent :: Mut Double
percent = nop

of' :: Double -> Mut Double
of' d p = spec (d * (p / 100))

stack :: Spec [Int]
stack = spec []

push :: AMut Int [Int]
push s v = spec (v : s)

pop :: Mut [Int]
pop = spec . tail

end :: Term [Int] [Int]
end = id
