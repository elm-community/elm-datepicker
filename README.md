# elm-datepicker

``` shell
elm package install elm-community/elm-datepicker
```

A reusable date picker component in Elm.


## Usage

The `DatePicker.init` function initialises the DatePicker. It returns the initialised DatePicker and associated `Cmds` so it must be done in your program's `init` or `update` functions:

**Note** Make sure you don't throw away the initial `Cmd`!

```elm
   
init : (Model, Cmd Msg)
...
    let
        ( datePicker, datePickerCmd ) =
            DatePicker.init 
    in
        (
            { model | datePicker = datePicker },
            Cmd.map SetDatePicker datePickerCmd
        )
```

The `DatePicker` can be displayed in a view using the `DatePicker.view` function. It returns its own
message type so you should wrap it in one of your own messages using `Html.map`:


```elm
type Msg
    = ...
    | SetDatePicker DatePicker.Msg
    | ...


view : Model -> Html Msg
view model =
    ...
    div [] [
        DatePicker.view
            model.date 
            someSettings
            model.startDatePicker 
         |> Html.map SetDatePicker
        ]

```

To handle `Msg` in your update function, you should unwrap the `DatePicker.Msg` and pass it down to the `DatePicker.update` function. The `DatePicker.update` function returns:

* the new model
* any command 
* the new date as a `DateEvent (Maybe Date)`, where `DateEvent` is really just `Maybe` with different semantics, to avoid a potentially confusing `Maybe Maybe`.

To create the settings to pass to `update`, DatePicker.defaultSettings` is provided to make it easier to use. You only have to override the settings that you are interested in.

**Note** The datepicker does _not_ retain an internal idea of a picked date in its model. That is, it depends completely on you for an idea of what date is chosen, so that third tuple member is important! Evan Czaplicki has a compelling argument for why components should not necessarily have an their own state for the primary data they manage [here](https://github.com/evancz/elm-sortable-table#single-source-of-truth).

```elm
someSettings : DatePicker.Settings
someSettings = 
    { defaultSettings
        | inputClassList = [ ( "form-control", True ) ]
        , inputId = Just "datepicker"
    }

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ...

         SetDatePicker msg ->
            let
                ( newDatePicker, datePickerCmd, dateEvent ) =
                    DatePicker.update someSettings msg model.startDatePicker

                date =
                    case dateEvent of
                        NoChange ->
                            model.date

                        Changed newDate ->
                            newDate |> processDate
            in
                { model
                    | date = date
                    , datePicker = newDatePicker
                }
                    ! [ Cmd.map SetDatePicker datePickerCmd ]

```

## Examples

See the [examples][examples] folder or try it on ellie-app: [simple] example and [bootstrap] example.

[examples]: https://github.com/elm-community/elm-datepicker/tree/master/examples
[simple]: https://ellie-app.com/5QFsDgQVva1/0
[bootstrap]: https://ellie-app.com/pwGJj5T6TBa1/0


## CSS

The CSS for the date picker is distributed separately.  You can grab
the compiled CSS from [here][compiled] or you can grab the SCSS source
from [here][scss].

[compiled]: https://github.com/elm-community/elm-datepicker/blob/master/css/elm-datepicker.css
[scss]: https://github.com/elm-community/elm-datepicker/blob/master/css/elm-datepicker.scss


## Running the acceptance tests
### Prerequisites

- elm reactor - this is most likely already installed if you're using Elm!
- chromedriver (https://sites.google.com/a/chromium.org/chromedriver/).
  Try `brew install chromedriver` if you're on OSX.


### Install the testing tools
run `npm install`

### build the examples
cd examples && make && cd ..

### Run the tests
`./run-acceptance-tests`

Please file an issue if you have any difficulty running the tests.
