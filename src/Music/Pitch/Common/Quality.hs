
-- | Common interval quality.
module Music.Pitch.Common.Quality
(
        -- * Quality
        Quality(..),
        qualityTypes,
        
        HasQuality(..),
        invertQuality,
        isPerfect,
        isMajor,
        isMinor,
        isAugmented,
        isDiminished,

        -- ** Quality type
        QualityType(..),
        expectedQualityType,

        -- ** Quality to alteration
        Direction(..),
        qualityToAlteration,

        qualityToDiff
) where

import           Music.Pitch.Augmentable
import           Music.Pitch.Common.Types
import           Music.Pitch.Common.Number

-- | Types of value that has an interval quality (mainly 'Interval' and 'Quality' itself).
class HasQuality a where
  quality :: a -> Quality

-- |
-- Returns whether the given quality is perfect.
--
isPerfect :: HasQuality a => a -> Bool
isPerfect a = case quality a of { Perfect -> True ; _ -> False }

-- |
-- Returns whether the given quality is major.
--
isMajor :: HasQuality a => a -> Bool
isMajor a = case quality a of { Major -> True ; _ -> False }

-- |
-- Returns whether the given quality is minor.
--
isMinor :: HasQuality a => a -> Bool
isMinor a = case quality a of { Minor -> True ; _ -> False }

-- |
-- Returns whether the given quality is augmented (including double augmented etc).
--
isAugmented :: HasQuality a => a -> Bool
isAugmented a = case quality a of { Augmented _ -> True ; _ -> False }

-- |
-- Returns whether the given quality is diminished (including double diminished etc).
--
isDiminished :: HasQuality a => a -> Bool
isDiminished a = case quality a of { Diminished _ -> True ; _ -> False }

instance HasQuality Quality where
  quality = id


-- | Augmentable Quality instance
--
-- This Augmentable instance exists solely for use of the extractQuality
-- function, which ensures that there is never any ambiguity around
-- diminished/augmented intervals turning into major/minor/perfect
-- intervals.

instance Augmentable Quality where
  augment Major                   = Augmented 1
  augment Minor                   = Major
  augment Perfect                 = Augmented 1
  augment (Augmented n)           = Augmented (n + 1)
  augment (Diminished n)          = Diminished (n - 1)

  diminish Major                  = Minor
  diminish Minor                  = Diminished 1
  diminish Perfect                = Diminished 1
  diminish (Augmented n)          = Augmented (n - 1)
  diminish (Diminished n)         = Diminished (n + 1)

-- |
-- Invert a quality.
--
-- Perfect is unaffected, major becomes minor and vice versa, augmented
-- becomes diminished and vice versa.
--
invertQuality :: Quality -> Quality
invertQuality = go
  where
    go Major            = Minor
    go Minor            = Major
    go Perfect          = Perfect
    go (Augmented n)    = Diminished n
    go (Diminished n)   = Augmented n


-- | 
-- The quality type expected for a given number, i.e. perfect for unisons, fourths,
-- and fifths and major/minor for everything else.  
expectedQualityType :: Number -> QualityType
expectedQualityType x = if ((abs x - 1) `mod` 7) + 1 `elem` [1,4,5]
  then PerfectType else MajorMinorType

-- |
-- Return all possible quality types for a given quality.
qualityTypes :: Quality -> [QualityType]
qualityTypes Perfect = [PerfectType]
qualityTypes Major   = [MajorMinorType]
qualityTypes Minor   = [MajorMinorType]
qualityTypes _       = [PerfectType, MajorMinorType]


data Direction = Upward | Downward
  deriving (Eq, Ord, Show)

-- |
-- Return the alteration in chromatic steps implied by the given quality
-- in the context of an interval of the specified type.
qualityToAlteration :: Direction -> QualityType -> Quality -> ChromaticSteps
qualityToAlteration positive qt q = fromIntegral $ go positive qt q
  where
    go Upward MajorMinorType (Augmented n)  = 0 + n
    go Upward MajorMinorType Major          = 0
    go Upward MajorMinorType Minor          = (-1)
    go Upward MajorMinorType (Diminished n) = -(1 + n)

    go Downward MajorMinorType (Augmented n)  = -(1 + n)
    go Downward MajorMinorType Major          = -1
    go Downward MajorMinorType Minor          = 0
    go Downward MajorMinorType (Diminished n) = 0 + n
    
    go Upward PerfectType (Augmented n)  = 0 + n
    go Upward PerfectType Perfect        = 0
    go Upward PerfectType (Diminished n) = 0 - n

    go Downward PerfectType (Augmented n)  = 0 - n
    go Downward PerfectType Perfect        = 0
    go Downward PerfectType (Diminished n) = 0 + n
    
    go _ qt q = error $ "qualityToDiff: Unknown interval expression (" ++ show qt ++ ", " ++ show q ++ ")"

qualityToDiff True  = qualityToAlteration Upward
qualityToDiff False = qualityToAlteration Downward
{-# DEPRECATED qualityToDiff "Use qualityToAlteration" #-}

