module DatePicker
    exposing
        ( Msg
        , Settings
        , DatePicker
        , defaultSettings
        , init
        , update
        , view
        )

{-| A customizable date picker component.

# Tea ☕
@docs Msg, DatePicker
@docs init, update, view

# Settings
@docs Settings, defaultSettings
-}

import Date exposing (Date, Day(..), Month(..), year, month, day)
import Html exposing (..)
import Html.Attributes exposing (href, placeholder, tabindex, type', value)
import Html.Events exposing (on, onBlur, onClick, onFocus, onWithOptions, targetValue)
import Json.Decode as Json
import Task


type alias Year =
    Int


type alias Day =
    Int


{-| An opaque type representing messages that are passed inside the DatePicker.
-}
type Msg
    = CurrentDate Date
    | NextMonth
    | PrevMonth
    | Pick Date
    | Focus
    | Blur
    | Change String
    | MouseDown
    | MouseUp


{-| The type of date picker settings.
-}
type alias Settings =
    { placeholder : String
    , classNamespace : String
    , isDisabled : Date -> Bool
    , dateFormatter : Date -> String
    , dayFormatter : Date.Day -> String
    , monthFormatter : Month -> String
    , pickedDate : Maybe Date
    }


type alias Model =
    { open : Bool
    , forceOpen : Bool
    , today : Date
    , currentMonth : Date
    , currentDates : List Date
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
    , isDisabled = always False
    , dateFormatter = formatDate
    , dayFormatter = formatDay
    , monthFormatter = formatMonth
    , pickedDate = Nothing
    }


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
            Maybe.withDefault initDate settings.pickedDate
    in
        ( DatePicker
            <| prepareDates date
                { open = False
                , forceOpen = False
                , today = initDate
                , currentMonth = initDate
                , currentDates = []
                , pickedDate = settings.pickedDate
                , settings = settings
                }
        , Task.perform (always <| CurrentDate initDate) CurrentDate Date.now
        )


prepareDates : Date -> Model -> Model
prepareDates date model =
    let
        start =
            firstOfMonth date |> subDays 6

        end =
            nextMonth date |> addDays 6

        dates =
            datesInRange start end
    in
        { model
            | currentMonth = date
            , currentDates = trimDates dates
        }


{-| The date picker reducer.
-}
update : Msg -> DatePicker -> ( DatePicker, Cmd Msg, Maybe Date )
update msg (DatePicker model) =
    case msg of
        CurrentDate date ->
            prepareDates (Maybe.withDefault date model.pickedDate) { model | today = date } ! []

        NextMonth ->
            prepareDates (nextMonth model.currentMonth) model ! []

        PrevMonth ->
            prepareDates (prevMonth model.currentMonth) model ! []

        Pick date ->
            ( DatePicker
                <| prepareDates date
                    { model
                        | pickedDate = Just date
                        , open = False
                    }
            , Cmd.none
            , Just date
            )

        Focus ->
            { model | open = True, forceOpen = False } ! []

        Blur ->
            { model | open = model.forceOpen } ! []

        Change inputDate ->
            let
                ( valid, pickedDate ) =
                    case Date.fromString inputDate of
                        Err _ ->
                            ( False, model.pickedDate )

                        Ok date ->
                            if model.settings.isDisabled date then
                                ( False, model.pickedDate )
                            else
                                ( True, Just date )

                month =
                    Maybe.withDefault model.currentMonth pickedDate
            in
                ( DatePicker <| prepareDates month { model | pickedDate = pickedDate }
                , Cmd.none
                , if valid then
                    pickedDate
                  else
                    Nothing
                )

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
            class' settings

        inputCommon xs =
            input
                ([ class "input"
                 , type' "text"
                 , on "change" (Json.map Change targetValue)
                 , onBlur Blur
                 , onClick Focus
                 , onFocus Focus
                 ]
                    ++ xs
                )
                []

        dateInput =
            case pickedDate of
                Nothing ->
                    inputCommon [ placeholder settings.placeholder ]

                Just date ->
                    inputCommon [ value <| settings.dateFormatter date ]
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
            class' settings

        classList =
            classList' settings

        dow d =
            td [ class "dow" ] [ text <| settings.dayFormatter d ]

        rows i xs racc acc =
            case xs of
                [] ->
                    List.reverse acc

                x :: xs ->
                    if i == 6 then
                        rows 0 xs [] (List.reverse (x :: racc) :: acc)
                    else
                        rows (i + 1) xs (x :: racc) acc

        picked d =
            case pickedDate of
                Nothing ->
                    datesEq d today

                Just date ->
                    datesEq d date

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
                        , ( "other-month", month currentMonth /= month d )
                        ]
                     ]
                        ++ props
                    )
                    [ text <| toString <| Date.day d ]

        row days =
            tr [ class "row" ] (List.map day days)

        days =
            List.map row (rows 0 currentDates [] [])

        onPicker ev =
            Json.succeed
                >> onWithOptions ev
                    { preventDefault = True
                    , stopPropagation = True
                    }
    in
        div
            [ class "picker"
            , onPicker "mousedown" MouseDown
            , onPicker "mouseup" MouseUp
            ]
            [ div [ class "picker-header" ]
                [ div [ class "prev-container" ]
                    [ a
                        [ class "prev"
                        , href "javascript:;"
                        , onClick PrevMonth
                        , tabindex -1
                        ]
                        []
                    ]
                , div [ class "month-container" ]
                    [ span [ class "month" ] [ text <| settings.monthFormatter <| month currentMonth ]
                    , span [ class "year" ] [ text <| toString <| year currentMonth ]
                    ]
                , div [ class "next-container" ]
                    [ a
                        [ class "next"
                        , href "javascript:;"
                        , onClick NextMonth
                        , tabindex -1
                        ]
                        []
                    ]
                ]
            , table [ class "table" ]
                [ thead [ class "weekdays" ]
                    [ tr []
                        [ dow Sun
                        , dow Mon
                        , dow Tue
                        , dow Wed
                        , dow Thu
                        , dow Fri
                        , dow Sat
                        ]
                    ]
                , tbody [ class "days" ] days
                ]
            ]


(!) : Model -> List (Cmd Msg) -> ( DatePicker, Cmd Msg, Maybe Date )
(!) m cs =
    ( DatePicker m, Cmd.batch cs, Nothing )


class' : Settings -> String -> Html.Attribute msg
class' { classNamespace } c =
    Html.Attributes.class (classNamespace ++ c)


classList' : Settings -> List ( String, Bool ) -> Html.Attribute msg
classList' { classNamespace } cs =
    List.map (\( c, b ) -> ( classNamespace ++ c, b )) cs
        |> Html.Attributes.classList


formatDate : Date -> String
formatDate date =
    toString (year date) ++ "/" ++ monthToString (month date) ++ "/" ++ dayToString (day date)


formatDay : Date.Day -> String
formatDay day =
    case day of
        Mon ->
            "Mo"

        Tue ->
            "Tu"

        Wed ->
            "We"

        Thu ->
            "Th"

        Fri ->
            "Fr"

        Sat ->
            "Sa"

        Sun ->
            "Su"


formatMonth : Month -> String
formatMonth month =
    case month of
        Jan ->
            "January"

        Feb ->
            "February"

        Mar ->
            "March"

        Apr ->
            "April"

        May ->
            "May"

        Jun ->
            "June"

        Jul ->
            "July"

        Aug ->
            "August"

        Sep ->
            "September"

        Oct ->
            "October"

        Nov ->
            "November"

        Dec ->
            "December"


trimDates : List Date -> List Date
trimDates dates =
    let
        dl dates =
            case dates of
                [] ->
                    []

                x :: xs ->
                    if Date.dayOfWeek x == Sun then
                        dates
                    else
                        dl xs

        dr dates =
            case dates of
                [] ->
                    []

                x :: xs ->
                    if Date.dayOfWeek x == Sat then
                        dates
                    else
                        dr xs
    in
        dl dates
            |> List.reverse
            |> dr
            |> List.reverse


datesInRange : Date -> Date -> List Date
datesInRange min max =
    let
        go x acc =
            let
                y =
                    subDay x
            in
                if datesEq y min then
                    y :: acc
                else
                    go y (y :: acc)
    in
        go max []


datesEq : Date -> Date -> Bool
datesEq a b =
    year a == year b && month a == month b && day a == day b


repeat : (a -> a) -> Int -> a -> a
repeat f =
    let
        go n x =
            if n == 0 then
                x
            else
                go (n - 1) (f x)
    in
        go


firstOfMonth : Date -> Date
firstOfMonth date =
    mkDate (year date) (month date) 1


nextMonth : Date -> Date
nextMonth date =
    let
        nextMonth =
            succMonth (month date)

        nextYear =
            if nextMonth == Jan then
                year date + 1
            else
                year date
    in
        mkDate nextYear nextMonth 1


prevMonth : Date -> Date
prevMonth date =
    let
        prevMonth =
            predMonth (month date)

        prevYear =
            if prevMonth == Dec then
                year date - 1
            else
                year date
    in
        mkDate prevYear prevMonth 1


addDays : Int -> Date -> Date
addDays =
    repeat addDay


subDays : Int -> Date -> Date
subDays =
    repeat subDay


addDay : Date -> Date
addDay date =
    let
        month =
            Date.month date

        year =
            Date.year date

        dim =
            daysInMonth year month

        day =
            Date.day date + 1

        succ =
            succMonth month

        succYear =
            if succ == Jan then
                year + 1
            else
                year
    in
        if day > dim then
            mkDate succYear succ 1
        else
            mkDate year month day


subDay : Date -> Date
subDay date =
    let
        month =
            Date.month date

        year =
            Date.year date

        day =
            Date.day date - 1

        pred =
            predMonth month

        predYear =
            if pred == Dec then
                year - 1
            else
                year
    in
        if day < 1 then
            mkDate predYear pred (daysInMonth predYear pred)
        else
            mkDate year month day


predMonth : Month -> Month
predMonth month =
    let
        prev =
            (monthToInt month - 1) `rem` 12
    in
        if prev == 0 then
            Dec
        else
            monthFromInt prev


succMonth : Month -> Month
succMonth month =
    monthFromInt (monthToInt month `rem` 12 + 1)


dayToString : Int -> String
dayToString day =
    if day < 10 then
        "0" ++ toString day
    else
        toString day


monthToString : Month -> String
monthToString month =
    let
        int =
            monthToInt month
    in
        if int < 10 then
            "0" ++ toString int
        else
            toString int


monthToInt : Month -> Int
monthToInt month =
    case month of
        Jan ->
            1

        Feb ->
            2

        Mar ->
            3

        Apr ->
            4

        May ->
            5

        Jun ->
            6

        Jul ->
            7

        Aug ->
            8

        Sep ->
            9

        Oct ->
            10

        Nov ->
            11

        Dec ->
            12


monthFromInt : Int -> Month
monthFromInt month =
    case month of
        1 ->
            Jan

        2 ->
            Feb

        3 ->
            Mar

        4 ->
            Apr

        5 ->
            May

        6 ->
            Jun

        7 ->
            Jul

        8 ->
            Aug

        9 ->
            Sep

        10 ->
            Oct

        11 ->
            Nov

        12 ->
            Dec

        x ->
            Debug.crash ("monthFromInt: invalid month: " ++ toString x)


daysInMonth : Year -> Month -> Int
daysInMonth year month =
    case month of
        Jan ->
            31

        Feb ->
            if isLeapYear year then
                29
            else
                28

        Mar ->
            31

        Apr ->
            30

        May ->
            31

        Jun ->
            30

        Jul ->
            31

        Aug ->
            31

        Sep ->
            30

        Oct ->
            31

        Nov ->
            30

        Dec ->
            31


isLeapYear : Year -> Bool
isLeapYear year =
    if year `rem` 100 == 0 then
        year `rem` 400 == 0
    else
        year `rem` 4 == 0


initDate : Date
initDate =
    mkDate 1992 May 29


mkDate : Year -> Month -> Day -> Date
mkDate year month day =
    toString year
        ++ "/"
        ++ monthToString month
        ++ "/"
        ++ toString day
        |> unsafeDate


unsafeDate : String -> Date
unsafeDate date =
    case Date.fromString date of
        Err _ ->
            Debug.crash "DatePicker.unsafeDate: failed to parse initial date"

        Ok date ->
            date
