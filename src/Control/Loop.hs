{-# LANGUAGE BangPatterns #-}

-- | Provides a convenient and fast alternative to the common
-- @forM_ [1..n]@ idiom, which in many cases GHC cannot fuse to efficient
-- code.
--
-- Notes on fast iteration:
--
-- * For `Int`, @(+1)@ is almost twice as fast as `succ` because `succ`
--   does an overflow check.
--
-- * For `Int`, you can get around that while still using `Enum` using
--   @toEnum . (+ 1) . fromEnum@.
--
-- * However, @toEnum . (+ 1) . fromEnum@ is slower than `succ` for
--   `Word32` on 64-bit machines since `toEnum` has to check if the
--   given `Int` exceeds 32 bits.
--
-- * Using @(+1)@ from `Num` is always the fastest way, but it gives
--   no overflow checking.
--
-- * Using `forLoop` you can flexibly pick the way of increasing the value
--   that best fits your needs.
--
-- * The currently recommended replacement for @forM_ [1..n]@ is
--   @forLoop 1 (<= n) (+1)@.
module Control.Loop
  ( forLoop
  , forLoopFold
  ) where


-- | @forLoop start cond inc f@: A C-style for loop with starting value,
-- loop condition and incrementor.
forLoop :: (Monad m) => a -> (a -> Bool) -> (a -> a) -> (a -> m ()) -> m ()
forLoop start cond inc f = go start
  where
    go !x | cond x    = f x >> go (inc x)
          | otherwise = return ()

{-# INLINE forLoop #-}


-- | @forLoopFold start cond inc acc0 f@: A pure fold using a for loop
-- instead of a list for performance.
--
-- Care is taken that @acc0@ not be strictly evaluated if unless done so by @f@.
forLoopFold :: a -> (a -> Bool) -> (a -> a) -> acc -> (acc -> a -> acc) -> acc
forLoopFold start cond inc acc0 f = go acc0 start
  where
    -- Not using !acc, see:
    --   http://neilmitchell.blogspot.co.uk/2013/08/destroying-performance-with-strictness.html
    go acc !x | cond x    = let acc' = f acc x
                             in acc' `seq` go acc' (inc x)
              | otherwise = acc

{-# INLINE forLoopFold #-}
