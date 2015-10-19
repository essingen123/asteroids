module Asteroid
  ( Asteroid
  , Size (..)
  , Kind (..)
  , newAsteroid
  , randomAsteroid
  , tickAsteroid
  , destroyAsteroid
  , asteroidSize
  , asteroidScore
  ) where

import Constants
import Data.Vec2 exposing (..)
import Random exposing (Seed)
import RandomHelpers exposing (..)
import Vec2Helpers exposing (..)


type Size
  = Big
  | Medium
  | Small


type Kind
  = A
  | B
  | C


type alias Asteroid =
  { sizeClass : Size
  , kind : Kind
  , position : Vec2
  , momentum : Vec2
  , size : Float
  , angle : Float
  }


defaultAsteroid : Asteroid
defaultAsteroid =
  { sizeClass = Big
  , size = asteroidSize Big
  , kind = A
  , position = origin
  , momentum = origin
  , angle = 0
  }


newAsteroid : Seed -> (Asteroid, Seed)
newAsteroid seed =
  let
    (boundsMin, boundsMax) = Constants.gameBounds
    (side, seed') = randomInt 0 4 seed
    (position, seed'') =
      if | side == 0 -> randomVec2Y seed' boundsMin.x boundsMin.y boundsMax.y
         | side == 1 -> randomVec2X seed' boundsMin.y boundsMin.x boundsMax.x
         | side == 2 -> randomVec2Y seed' boundsMax.x boundsMin.y boundsMax.y
         | otherwise -> randomVec2X seed' boundsMax.y boundsMin.x boundsMax.x
    asteroid =
      { defaultAsteroid
      | position <- position
      }
  in
    (asteroid, seed'')
    |> randomizeNewAsteroidProperties


randomAsteroid : Seed -> (Asteroid, Seed)
randomAsteroid seed =
  let
    (sizeSelect, seed') = randomInt 0 3 seed
    size = if | sizeSelect == 0 -> Big
              | sizeSelect == 1 -> Medium
              | otherwise -> Small
    (position, seed'') = randomVec2InBounds seed' Constants.gameBounds
    asteroid =
      { defaultAsteroid
      | sizeClass <- size
      , size <- asteroidSize size
      , position <- position
      }
  in
    (asteroid, seed'')
    |> randomizeNewAsteroidProperties


randomizeNewAsteroidProperties : (Asteroid, Seed) -> (Asteroid, Seed)
randomizeNewAsteroidProperties input =
  input
  |> randomKind
  |> randomAngle
  |> randomMomentum


randomKind : (Asteroid, Seed) -> (Asteroid, Seed)
randomKind (asteroid, seed) =
  let
    (kindInt, seed') = randomInt 0 3 seed
    kind =
      if | kindInt == 0 -> A
         | kindInt == 1 -> B
         | otherwise -> C
  in
     ({asteroid | kind <- kind}, seed')


randomAngle : (Asteroid, Seed) -> (Asteroid, Seed)
randomAngle (asteroid, seed) =
  let
    (angle, seed') = randomFloat 0 (2 * pi) seed
  in
    ({asteroid | angle <- angle}, seed')


randomMomentum : (Asteroid, Seed) -> (Asteroid, Seed)
randomMomentum (asteroid, seed) =
  let
    (momentum, seed') = newMomentum asteroid.sizeClass seed
  in
    ({asteroid | momentum <- momentum}, seed')


tickAsteroid : Asteroid -> Asteroid
tickAsteroid asteroid =
  { asteroid
  | position <-
      addVec asteroid.position asteroid.momentum
      |> wrapVec2 Constants.gameBounds
  }


newMomentum : Size -> Seed -> (Vec2, Seed)
newMomentum size seed =
  let
    (momentum, seed') =
      case size of
        Big -> randomVec2 seed -Constants.asteroidSpeedBig Constants.asteroidSpeedBig
        Medium -> randomVec2 seed -Constants.asteroidSpeedMedium Constants.asteroidSpeedMedium
        Small -> randomVec2 seed -Constants.asteroidSpeedSmall Constants.asteroidSpeedSmall
    mag = magnitude momentum
    momentum' =
      if mag < Constants.asteroidSpeedMin then
        scaleVec (Constants.asteroidSpeedMin / mag) momentum
      else
        momentum
  in (momentum', seed')



destroyAsteroid : Asteroid -> Seed -> Maybe (Asteroid, Asteroid, Seed)
destroyAsteroid asteroid seed =
  case asteroid.sizeClass of
    Big -> Just (splitAsteroid asteroid Medium seed)
    Medium -> Just (splitAsteroid asteroid Small seed)
    Small -> Nothing


splitAsteroid : Asteroid -> Size -> Seed -> (Asteroid, Asteroid, Seed)
splitAsteroid asteroid size seed =
  let
    newAsteroid =
      { asteroid
      | sizeClass <- size
      , size <- asteroidSize size
      }
    (a, seed') = (newAsteroid, seed) |> randomizeNewAsteroidProperties
    (b, seed'') = (newAsteroid, seed') |> randomizeNewAsteroidProperties
  in
    ( a |> tickAsteroid
    , b |> tickAsteroid
    , seed''
    )


splitAsteroids : List Asteroid -> Seed -> (List Asteroid, Seed)
splitAsteroids asteroids seed =
  (asteroids, seed)


asteroidSize : Size -> Float
asteroidSize size =
  case size of
    Big -> Constants.asteroidSizeBig
    Medium -> Constants.asteroidSizeMedium
    Small -> Constants.asteroidSizeSmall


asteroidScore : Asteroid -> Int
asteroidScore asteroid =
  case asteroid.sizeClass of
    Big -> Constants.asteroidScoreBig
    Medium -> Constants.asteroidScoreMedium
    Small -> Constants.asteroidScoreSmall