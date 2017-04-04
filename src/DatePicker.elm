module DatePicker
    exposing
        ( Msg
        , Settings
        , DatePicker
        , defaultSettings
        , init
        , update
        , view
        , getDate
        , setDate
        , setFilter
        , isOpen
        , between
        , moreOrLess
        , off
        )

{-| A customizable date picker component.

# Tea ☕
@docs Msg, DatePicker
@docs init, update, view, getDate, setDate, setFilter, isOpen

# Settings
@docs Settings, defaultSettings, between, moreOrLess, off
-}

import Date exposing (Date, Day(..), Month, day, month, year)
import DatePicker.Date exposing (..)
import Html exposing (..)
import Html.Attributes as Attrs exposing (href, placeholder, tabindex, type_, value, selected)
import Html.Events exposing (on, onBlur, onClick, onInput, onFocus, onWithOptions, targetValue)
import Html.Keyed
import Json.Decode as Json
import Task


{-| An opaque type representing messages that are passed inside the DatePicker.
-}
type Msg
    = CurrentDate Date
    | NextMonth
    | PrevMonth
    | Pick Date
    | ChangeYear String
    | Text String
    | Change
    | Focus
    | Blur
    | MouseDown
    | MouseUp


{-| The type of date picker settings.
-}
type alias Settings =
    { placeholder : String
    , classNamespace : String
    , inputClassList : List ( String, Bool )
    , inputName : Maybe String
    , inputId : Maybe String
    , isDisabled : Date -> Bool
    , parser : String -> Result String Date
    , dateFormatter : Date -> String
    , dayFormatter : Day -> String
    , monthFormatter : Month -> String
    , yearFormatter : Int -> String
    , cellFormatter : String -> Html Msg
    , firstDayOfWeek : Day
    , pickedDate : Maybe Date
    , changeYear : YearRange
    }


type alias Model =
    { open : Bool
    , forceOpen : Bool
    , today : Date
    , currentMonth : Date
    , currentDates : List Date
    , inputText : String
    , pickedDate : Maybe Date
    , settings : Settings
    }


{-| The DatePicker model.
-}
type DatePicker
    = DatePicker Model


{-| A record of default settings for the date picker.  Extend this if
you want to customize your date picker.


    import DatePicker exposing (defaultSettings)

    DatePicker.init { defaultSettings | placeholder = "Pick a date" }


To disable certain dates:


    import Date exposing (Day(..), dayOfWeek)
    import DatePicker exposing (defaultSettings)

    DatePicker.init { defaultSettings | isDisabled = \d -> dayOfWeek d `List.member` [ Sat, Sun ] }

-}
defaultSettings : Settings
defaultSettings =
    { placeholder = "Please pick a date..."
    , classNamespace = "elm-datepicker--"
    , inputClassList = []
    , inputName = Nothing
    , inputId = Nothing
    , isDisabled = always False
    , parser = Date.fromString
    , dateFormatter = formatDate
    , dayFormatter = formatDay
    , monthFormatter = formatMonth
    , yearFormatter = toString
    , cellFormatter = formatCell
    , firstDayOfWeek = Sun
    , pickedDate = Nothing
    , changeYear = off
    }


yearRangeActive : YearRange -> Bool
yearRangeActive yearRange =
    yearRange /= Off


{-| Select a range of date to display


    DatePicker.init { defaultSettings | changeYear = between 1555 2018 }

-}
between : Int -> Int -> YearRange
between start end =
    if start > end then
        Between end start
    else
        Between start end


{-| Select a symmetric range of date to display


    DatePicker.init { defaultSettings | changeYear = moreOrLess 10 }

-}
moreOrLess : Int -> YearRange
moreOrLess range =
    MoreOrLess range


{-| Turn off the date range


    DatePicker.init { defaultSettings | changeYear = off }

-}
off : YearRange
off =
    Off


formatCell : String -> Html Msg
formatCell day =
    text day


{-| Initialize a DatePicker given a Settings record.  You must execute
the returned command for the date picker to behave correctly.


    init =
      let
         (datePicker, datePickerFx) =
           DatePicker.init defaultSettings
      in
         { picker = datePicker } ! [ Cmd.map ToDatePicker datePickerfx ]

-}
init : Settings -> ( DatePicker, Cmd Msg )
init settings =
    let
        date =
            settings.pickedDate ?> initDate
    in
        ( DatePicker <|
            prepareDates date
                { open = False
                , forceOpen = False
                , today = initDate
                , currentMonth = initDate
                , currentDates = []
                , inputText =
                    settings.pickedDate
                        |> Maybe.map settings.dateFormatter
                        |> Maybe.withDefault ""
                , pickedDate = settings.pickedDate
                , settings = settings
                }
        , Task.perform CurrentDate Date.now
        )


prepareDates : Date -> Model -> Model
prepareDates date ({ settings } as model) =
    let
        start =
            firstOfMonth date |> subDays 6

        end =
            nextMonth date |> addDays 6
    in
        { model
            | currentMonth = date
            , currentDates = datesInRange settings.firstDayOfWeek start end
        }


{-|
Extract the current set date (if set) from a datepicker
-}
getDate : DatePicker -> Maybe Date
getDate (DatePicker model) =
    model.pickedDate


{-|
Set a new date in the datepicker
-}
setDate : Date -> DatePicker -> DatePicker
setDate date (DatePicker model) =
    DatePicker
        { model
            | pickedDate = Just date
            , inputText = model.settings.dateFormatter date
        }


{-|
Expose if the datepicker is open
-}
isOpen : DatePicker -> Bool
isOpen (DatePicker model) =
    model.open


{-|
Set the function that marks days valid or invalid, so for example if you need to build a date range you can keep those in sync

-}
setFilter : (Date -> Bool) -> DatePicker -> DatePicker
setFilter isDisabled (DatePicker model) =
    let
        s =
            model.settings

        newSettings =
            { s | isDisabled = isDisabled }
    in
        DatePicker { model | settings = newSettings }


{-| The date picker update function.  The third value in the returned
tuple represents the picked date, it is `Nothing` if no date was
picked or if the previously-picked date has not changed and `Just`
some date if it has.
-}
update : Msg -> DatePicker -> ( DatePicker, Cmd Msg, Maybe Date )
update msg (DatePicker ({ forceOpen, currentMonth, pickedDate, settings } as model)) =
    case msg of
        CurrentDate date ->
            prepareDates (pickedDate ?> date) { model | today = date } ! []

        NextMonth ->
            prepareDates (nextMonth currentMonth) model ! []

        PrevMonth ->
            prepareDates (prevMonth currentMonth) model ! []

        Pick date ->
            ( DatePicker <|
                prepareDates date
                    { model
                        | pickedDate = Just date
                        , open = False
                        , inputText = settings.dateFormatter date
                    }
            , Cmd.none
            , Just date
            )

        ChangeYear year ->
            prepareDates (newYear model.currentMonth year) model ! []

        Text text ->
            { model | inputText = text } ! []

        Change ->
            let
                ( valid, newPickedDate ) =
                    case settings.parser model.inputText of
                        Err _ ->
                            ( False, pickedDate )

                        Ok date ->
                            if settings.isDisabled date then
                                ( False, pickedDate )
                            else
                                ( True, Just date )

                month =
                    newPickedDate ?> currentMonth
            in
                ( DatePicker <|
                    prepareDates month
                        { model
                            | pickedDate = newPickedDate
                            , inputText =
                                newPickedDate
                                    |> Maybe.map settings.dateFormatter
                                    |> Maybe.withDefault ""
                        }
                , Cmd.none
                , if valid then
                    newPickedDate
                  else
                    Nothing
                )

        Focus ->
            { model | open = True, forceOpen = False } ! []

        Blur ->
            { model | open = forceOpen } ! []

        MouseDown ->
            { model | forceOpen = True } ! []

        MouseUp ->
            { model | forceOpen = False } ! []


{-| The date picker view.
-}
view : DatePicker -> Html Msg
view (DatePicker ({ open, pickedDate, settings } as model)) =
    let
        class =
            mkClass settings

        potentialInputId =
            settings.inputId
                |> Maybe.map Attrs.id
                |> (List.singleton >> List.filterMap identity)

        inputClasses =
            [ ( settings.classNamespace ++ "input", True ) ]
                ++ settings.inputClassList

        inputCommon xs =
            input
                ([ Attrs.classList inputClasses
                 , Attrs.name (settings.inputName ?> "")
                 , type_ "text"
                 , on "change" (Json.succeed Change)
                 , onInput Text
                 , onBlur Blur
                 , onClick Focus
                 , onFocus Focus
                 ]
                    ++ potentialInputId
                    ++ xs
                )
                []

        dateInput =
            inputCommon
                [ placeholder settings.placeholder
                , value model.inputText
                ]
    in
        div [ class "container" ]
            [ dateInput
            , if open then
                datePicker model
              else
                text ""
            ]


datePicker : Model -> Html Msg
datePicker { today, currentMonth, currentDates, pickedDate, settings } =
    let
        class =
            mkClass settings

        classList =
            mkClassList settings

        firstDay =
            settings.firstDayOfWeek

        arrow className message =
            a
                [ class className
                , href "javascript:;"
                , onClick message
                , tabindex -1
                ]
                []

        dow d =
            td [ class "dow" ] [ text <| settings.dayFormatter d ]

        picked d =
            case pickedDate of
                Nothing ->
                    dateTuple d == dateTuple today

                Just date ->
                    dateTuple d == dateTuple date

        day d =
            let
                disabled =
                    settings.isDisabled d

                props =
                    if not disabled then
                        [ onClick (Pick d) ]
                    else
                        []
            in
                td
                    ([ classList
                        [ ( "day", True )
                        , ( "disabled", disabled )
                        , ( "picked", picked d )
                        , ( "today", dateTuple d == dateTuple today )
                        , ( "other-month", month currentMonth /= month d )
                        ]
                     ]
                        ++ props
                    )
                    [ settings.cellFormatter <| toString <| Date.day d ]

        row days =
            tr [ class "row" ] (List.map day days)

        days =
            List.map row (groupDates currentDates)

        onPicker ev =
            Json.succeed
                >> onWithOptions ev
                    { preventDefault = False
                    , stopPropagation = True
                    }

        onChange handler =
            on "change" <| Json.map handler targetValue

        isCurrentYear selectedYear =
            year currentMonth == selectedYear

        yearOption index selectedYear =
            ( toString index
            , option [ value (toString selectedYear), selected (isCurrentYear selectedYear) ]
                [ text (toString <| selectedYear) ]
            )

        dropdownYear =
            Html.Keyed.node "select" [ onChange ChangeYear, class "year-menu" ] (List.indexedMap yearOption (yearRange currentMonth settings.changeYear))
    in
        div
            [ class "picker"
            , onPicker "mousedown" MouseDown
            , onPicker "mouseup" MouseUp
            ]
            [ div [ class "picker-header" ]
                [ div [ class "prev-container" ]
                    [ arrow "prev" PrevMonth ]
                , div [ class "month-container" ]
                    [ span [ class "month" ]
                        [ text <| settings.monthFormatter <| month currentMonth ]
                    , span [ class "year" ]
                        [ if not (yearRangeActive settings.changeYear) then
                            text <| settings.yearFormatter <| year currentMonth
                          else
                            Html.Keyed.node "span" [] [ ( toString (year currentMonth), dropdownYear ) ]
                        ]
                    ]
                , div [ class "next-container" ]
                    [ arrow "next" NextMonth ]
                ]
            , table [ class "table" ]
                [ thead [ class "weekdays" ]
                    [ tr []
                        [ dow <| firstDay
                        , dow <| addDows 1 firstDay
                        , dow <| addDows 2 firstDay
                        , dow <| addDows 3 firstDay
                        , dow <| addDows 4 firstDay
                        , dow <| addDows 5 firstDay
                        , dow <| addDows 6 firstDay
                        ]
                    ]
                , tbody [ class "days" ] days
                ]
            ]


{-| Turn a list of dates into a list of date rows with 7 columns per
row representing each day of the week.
-}
groupDates : List Date -> List (List Date)
groupDates dates =
    let
        go i xs racc acc =
            case xs of
                [] ->
                    List.reverse acc

                x :: xs ->
                    if i == 6 then
                        go 0 xs [] (List.reverse (x :: racc) :: acc)
                    else
                        go (i + 1) xs (x :: racc) acc
    in
        go 0 dates [] []


mkClass : Settings -> String -> Html.Attribute msg
mkClass { classNamespace } c =
    Attrs.class (classNamespace ++ c)


mkClassList : Settings -> List ( String, Bool ) -> Html.Attribute msg
mkClassList { classNamespace } cs =
    List.map (\( c, b ) -> ( classNamespace ++ c, b )) cs
        |> Attrs.classList


(!) : Model -> List (Cmd Msg) -> ( DatePicker, Cmd Msg, Maybe Date )
(!) m cs =
    ( DatePicker m, Cmd.batch cs, Nothing )


(?>) : Maybe a -> a -> a
(?>) =
    flip Maybe.withDefault
