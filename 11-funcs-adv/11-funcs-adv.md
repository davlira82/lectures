---
title: "Functions in R: 2) Advanced concepts"
author:
  name: Grant R. McDermott
  affiliation: University of Oregon | EC 607
  # email: grantmcd@uoregon.edu
date: Lecture 11  #"12 February 2019"
output: 
  html_document:
    theme: flatly
    highlight: haddock 
    # code_folding: show
    toc: yes
    toc_depth: 4
    toc_float: yes
    keep_md: true
---



## Software requirements

### R packages 

- **New:** `R.cache`
- **Already used:** `tidyverse` 

Install (if necessary) and load these packages now:


```r
if (!require("pacman")) install.packages("pacman")
pacman::p_load(R.cache, tidyverse)
```

## Catching (user) errors and mistakes

In the previous lecture, we implicitly assumed that the user knows exactly how to use our function. However, this isn't always the case. A related, but more complicated, case is when we mistakenly input the wrong type of argument into a function. For example, consider what happens when we mistakenly enter a string rather than a number in our `square` function from last time.


```r
square <- 
  function (x = 1) { ## Setting the default argument value 
    x_sq <- x^2 
    df <- tibble(value=x, value_squared=x_sq)
    return(df)
  }

square("1") 
```

```
## Error in x^2: non-numeric argument to binary operator
```

This may just seem like a case of particularly dumb user error. However --- trust me --- its very easy to run into this category of problem when you have a complex analysis that consists of, say, a series of nested functions. (One function calling another, calling another...) For whatever reason, a single function or iteration may produce slightly different output than expected and this can bring your entire analysis crashing to its knees, because the output can't be used in the next part of the chain. This is especially frustrating when you are running a multicore process (e.g. a parallel Monte Carlo simulation), since the program will first complete the *entire* run --- perhaps taking several hours --- before informing you right at the end that there was an error somewhere and no results (even for the valid iterations!) have been retained. 

Luckily, there are several approaches to guarding against these kind of mistakes. I'll briefly run through what I see as the three main options below. 

1. Function-specific `ifelse` statements
2. Improved generality with `base::tryCatch()`
3. Use `purrr::safely()` and family

### Option 1: Function-specific `ifelse` statements

In this particular example, we can check whether the input argument is a numeric and use an `ifelse` statement to produce a warning/error message if it fails this test. Let's demonstrate how this might work in practice by defining a slightly modified version of our function, which I'll call `square_ifelse`.

```r
square_ifelse <- 
  function (x = 1) { 
    if (is.numeric(x)) { ## Check that this is a valid argument to our function.
      x_sq <- x^2 
      df <- tibble(value=x, value_squared=x_sq)
      return(df) 
    } else { ## Return a warning message if not.
      message("Sorry, you need to provide a numeric input variable.")
    }
  }
```

Test it.

```r
square_ifelse("1") ## Will trigger our warning message.
```

```
## Sorry, you need to provide a numeric input variable.
```

```r
square_ifelse(1) ## Works.
```

```
##   value value_squared
## 1     1             1
```

### Option 2: Improved generality with `base::tryCatch()`

Another, more general option is to use the `base::tryCatch()` function for handling errors and warnings. Let me demonstrate its usefulness with two separate examples. 

#### 2.1) Wrap `tryCatch()` around an entire function

The first simply wraps a generic `tryCatch` statement *around* our existing `square` function. Note the invocation of R's in-built "error" class, which in turn is passed to another in-built function called `message`. Basically, we are telling R to produce a particular message whenever it recognizes that an error (any error!) has occurred while executing our bespoke function.

```r
tryCatch(
  square("three"), 
  error = function(e) message("Sorry, something went wrong. Did you try to square a string instead of a number?")
  )
```

```
## Sorry, something went wrong. Did you try to square a string instead of a number?
```

This first example works well, but it has the downside of throwing out everything that went into the function in favour of a single error message. Not only that, but it could throw out potentially valid input-output because of a single error. To see this more clearly, let's feed our function a vector of inputs, where only one input is invalid.


```r
tryCatch(
  square(c(1,2,"three")), 
  error = function(e) message("Sorry, something went wrong. Did you try to square a string instead of a number?")
  )
```

```
## Sorry, something went wrong. Did you try to square a string instead of a number?
```
So we simply get an error message, even though some (most) of our inputs were valid. In an ideal world, we would have retained the input-output from the valid parameters (i.e. 1 and 2) and only received an error message for the single invalid case (i.e. "three"). This leads us to our second example...

#### 2.2) Use `tryCatch()` inside a function

The second example avoids the above problem by invoking `tryCatch()` *inside* our user-defined function. The principle is very much the same as before: We're going to tell R what to give us whenever it encounters an error. However, we are going to be more explicit about where we expect that error to occur. Moreover, instead of simply producing an error message, this time we'll instruct R to return an explicit, alternative value (i.e. `NA`).


```r
square_trycatch <-
  function (x = 1) {
    x_sq <- tryCatch(x^2, error = function(e) NA_real_) ## tryCatch goes here now. Produce an NA value if we can't square the input.
    df <- tibble(value=x, value_squared=x_sq)
    return(df)
  }
```

Let's see that it works on our previous input vector, where only one input was invalid.


```r
square_trycatch(c(1,2,"three"))
```

```
##   value value_squared
## 1     1            NA
## 2     2            NA
## 3 three            NA
```

Huh? Looks like it half worked. We get the input values, but R's vectorised nature (normally such a good thing!) has converted *all* of the squared output values to `NA` because of the one bad apple. Why? Well, let's look at our input vector again:


```r
str(c(1,2,"three"))
```

```
##  chr [1:3] "1" "2" "three"
```

*Ah-ha...* R has converted every element in the vector to a character string. Remember that vectors in R are assumed to contain only elements of the same type. The solution is to use an input array that allows different element types --- i.e. a *list*. This, in turn, requires modifying the way that we invoke the function by putting it in a `base::lapply()` or `purrr::map()` call. As you'll hopefully remember from the last lecture, these two functions are syntactically identical.


```r
## Using base::lapply
lapply(list(1,2,"three"), square_trycatch) 
```

```
## [[1]]
## # A tibble: 1 x 2
##   value value_squared
##   <dbl>         <dbl>
## 1     1             1
## 
## [[2]]
## # A tibble: 1 x 2
##   value value_squared
##   <dbl>         <dbl>
## 1     2             4
## 
## [[3]]
## # A tibble: 1 x 2
##   value value_squared
##   <chr>         <dbl>
## 1 three            NA
```

```r
## Using purrr:map
map(list(1,2,"three"),  square_trycatch) 
```

```
## [[1]]
## # A tibble: 1 x 2
##   value value_squared
##   <dbl>         <dbl>
## 1     1             1
## 
## [[2]]
## # A tibble: 1 x 2
##   value value_squared
##   <dbl>         <dbl>
## 1     2             4
## 
## [[3]]
## # A tibble: 1 x 2
##   value value_squared
##   <chr>         <dbl>
## 1 three            NA
```

As we practiced last lecture, we may wish to bind the resulting list of data frames into a single data frame using `dplyr::bind_rows()` or, more simply, `purrr::map_df()`. However, that actually produces errors of its own because all of the columns need to be the same. 


```r
map_df(list(1,2,"three"),  square_trycatch)
```

```
## Error in bind_rows_(x, .id): Column `value` can't be converted from numeric to character
```

The somewhat pedantic solution is to make sure that the offending input is coerced to a numeric within the function itself. Note that this will introduce coercion warnings of its own, but at least it won't fail. 


```r
square_trycatch2 <-
  function (x = 1) {
    x_sq <- tryCatch(x^2, error = function(e) NA_real_) 
    df <- tibble(value=as.numeric(x), value_squared=x_sq) ## Convert input to numeric
    return(df)
  }

map_df(list(1,2,"three"), square_trycatch2)
```

```
## Warning in eval_tidy(xs[[i]], unique_output): NAs introduced by coercion
```

```
## # A tibble: 3 x 2
##   value value_squared
##   <dbl>         <dbl>
## 1     1             1
## 2     2             4
## 3    NA            NA
```

### Option 3: Use `purrr::safely()` and family

Finally, for those of you who prefer a tidyverse equivalent of `tryCatch()`, you can use `purrr::safely()` and its related functions (including `purrr::possibly()` and other variants). I won't go through the entire rigmarole again, so here's a simple flavour of how they work:


```r
square_simple <-
  function (x = 1) {
    x_sq <- x^2
  }
square_safely <- safely(square_simple)
square_safely("three")
```

```
## $result
## NULL
## 
## $error
## <simpleError in x^2: non-numeric argument to binary operator>
```

```r
square_safely("three")$result
```

```
## NULL
```

And you can specify default behaviour:


```r
square_safely <- safely(square_simple, otherwise = NA_real_)
square_safely("three")
```

```
## $result
## [1] NA
## 
## $error
## <simpleError in x^2: non-numeric argument to binary operator>
```

```r
square_safely("three")$result
```

```
## [1] NA
```