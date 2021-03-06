module Material.Internal.Options exposing
    ( Property
    , apply
    , attribute
    , class
    , collect
    , for
    , id
    , noOp
    , onBlur
    , onClick
    , onFocus
    , onInput
    , style
    , styled
    , updateConfig
    , when
    )

import Html exposing (Attribute)
import Html.Attributes as Attr
import Html.Events as Events


type Property config msg
    = Class String
    | Style String String
    | Attribute (Attribute msg)
    | UpdateConfig (config -> config)
    | NoOp


type alias Summary config msg =
    { classNames : List String
    , styles : List ( String, String )
    , attrs : List (Attribute msg)
    , config : config
    }


collect : config -> List (Property config msg) -> Summary config msg
collect config =
    collectHelp (initialSummary config)


collectHelp : Summary config msg -> List (Property config msg) -> Summary config msg
collectHelp =
    List.foldl collect1


collectWithoutConfig : List (Property config msg) -> Summary () msg
collectWithoutConfig =
    List.foldl collectWithoutConfig1 (initialSummary ())


collect1 : Property config msg -> Summary config msg -> Summary config msg
collect1 option summary =
    case option of
        Class className ->
            { summary | classNames = className :: summary.classNames }

        Style prop val ->
            { summary | styles = ( prop, val ) :: summary.styles }

        Attribute attr ->
            { summary | attrs = attr :: summary.attrs }

        UpdateConfig f ->
            { summary | config = f summary.config }

        NoOp ->
            summary


collectWithoutConfig1 : Property config msg -> Summary () msg -> Summary () msg
collectWithoutConfig1 option summary =
    case option of
        Class className ->
            { summary | classNames = className :: summary.classNames }

        Style prop val ->
            { summary | styles = ( prop, val ) :: summary.styles }

        Attribute attr ->
            { summary | attrs = attr :: summary.attrs }

        UpdateConfig _ ->
            summary

        NoOp ->
            summary


initialSummary : config -> Summary config msg
initialSummary config =
    { classNames = []
    , styles = []
    , attrs = []
    , config = config
    }


apply :
    Summary config msg
    -> (List (Attribute msg) -> a)
    -> List (Property config msg)
    -> List (Attribute msg)
    -> a
apply summary ctor properties attrs =
    ctor (addAttrs (collectHelp summary properties) attrs)


addAttrs : Summary config msg -> List (Attribute msg) -> List (Attribute msg)
addAttrs summary attrs =
    summary.attrs
        ++ [ Attr.class (String.join " " summary.classNames) ]
        ++ List.map (\( prop, val ) -> Attr.style prop val) summary.styles
        ++ attrs


class : String -> Property config msg
class name =
    Class name


style : String -> String -> Property config msg
style prop val =
    Style prop val


updateConfig : (config -> config) -> Property config msg
updateConfig =
    UpdateConfig


styled :
    (List (Attribute msg) -> a)
    -> List (Property config msg)
    -> a
styled ctor properties =
    ctor (addAttrs (collectWithoutConfig properties) [])


onClick : msg -> Property config msg
onClick msg =
    Attribute <| Events.onClick msg


onInput : (String -> msg) -> Property config msg
onInput msg =
    Attribute <| Events.onInput msg


onFocus : msg -> Property config msg
onFocus msg =
    Attribute <| Events.onFocus msg


onBlur : msg -> Property config msg
onBlur msg =
    Attribute <| Events.onBlur msg


attribute : Attribute msg -> Property config msg
attribute attr =
    Attribute attr


noOp : Property config msg
noOp =
    NoOp


when : Bool -> Property config msg -> Property config msg
when guard prop =
    if guard then
        prop

    else
        noOp


id : Maybe String -> Property config msg
id val =
    Maybe.map (Attribute << Attr.id) val
        |> Maybe.withDefault noOp


for : Maybe String -> Property config msg
for val =
    Maybe.map (Attribute << Attr.for) val
        |> Maybe.withDefault noOp
