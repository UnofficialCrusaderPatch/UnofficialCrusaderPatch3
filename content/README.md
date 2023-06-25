# Configurations in UCP3

## Overview
1. Structure of the framework: extensions, plugins, and modules
2. Configuration of UCP3 components
3. Required vs Suggested: Detailed specification of config entries
4. Final configuration file for the backend

Appendix 1. Implementation details
Appendix 2. Overview of options specification

## 1. Structure of the framework
The framework is built up in a modular fashion. There are modules and plugins. Each of them live in their own folder: `ucp/modules` and `ucp/plugins`.

### Modules
Modules are unopinionated extensions that contain new code or modifications to existing code for the game,
in a general form, such that end-users are free to specify the parameters of the modification and can toggle features on and off.

Because modules touch executable memory and interact with the game in a direct fashion, they need to be trusted before they can run. A special developer version of UCP3 bypasses the trust system.

#### Example
A module named UnitParameterTweaker version 0.0.1 has the path: `ucp/modules/UnitParameterTweaker-0.0.1.zip` (zipped because it is a module that needs to be verified and trusted at runtime)

### Plugins
Plugins are extensions that contain content, such as new files such as new gfx, sfx, maps, new AI, etc. 
Furthermore, plugins can call functions that modules provide through lua.
The files of plugins live in their own folder. Game resources live in the resources subfolder of the plugin.

Because plugins do not touch executable memory and only interact with the game via modules, they don't need to be trusted.

#### Example
The custom maps of a plugin named symmetricalMaps version 0.0.1 have the path: `ucp/plugins/symmetricalMaps-0.0.1/resources/maps`

## 2. Configuration of UCP3 components

Options that can be configured are uniquely identified with a path/url/key (I am using these terms as synonyms of the same thing).
In this document, I will refer to those as the `url`.

An url is a concatenation of words using `.` as the separator. The purpose of this is that it keeps config.yml files (see below) tidy.

### Example of a URL
```yaml
# literal url representation of a URL as used in options.yml
- name: option1
  url: featureset1.feature2.option1
  display: slider
  contents:
    type: integer
    min: 0
    max: 100
    value: 10

# path representation of a URL as used in config.yml files
config:
  featureset1:
    feature2:
      option1:
        contents:
          value: 90
```

### Options.yml: providing options to end users
A module can provide an `options.yml` which specifies what options the module provides. For example, if the module changes how AI buys wood in the game, then this file specifies toggles and customisations to let an end-user tweak it.
Since modules are unopinionated, they should provide as much flexibility and options to end-users as is sensible.

Entries in the `options.yml` have default values, and these defaults should preferably be the same as the vanilla game.

A plugin can also provide an `options.yml`. For example, if a plugin creator knows end-users might want to switch off a certain part of the custom content, e.g. sound effects, then the creator can specify that in this file.

### Config.yml: demanding configurations from other modules and plugins
A module and a plugin can also provide a `config.yml` which specifies the configuration demands of the module or plugin. 

#### Example
If a module existed that tweaks unit health parameters, then a plugin can demand that these parameters are set to a certain value or within a certain range.
Thus, if a creator wants to create an "Ultimate AI" plugin, then they specify which options of which modules need to be set in which way to create this experience.

## 3. Required vs suggested: detailed specification
To give content creators even more flexibility, entries in the `config.yml` can have a `suggested-` or `required-` prefix, 
indicating to what extent the demanded values are a requirement or a suggestion.

Requirements throw errors if they are in conflict with other required configuration demands from other plugins and modules.
Suggestions essentially serve as a new default value of an option and can be overriden by new suggestions and requirements.

### Example
A module named A provides the following option in the `options.yml`
```yml
specification-version: 1.0.0
options:
- name: option1
  url: option1
  display: slider
  contents:
    type: integer
    min: 0
    max: 20
    value: 10
```

A plugin B requires the following value for it in its `config.yml`
```yml
modules:
  A: # Module name
    option1:
      contents:
        required-min: 8
        required-max: 20
        suggested-value: 12
```

Note that both file formats have an intermediate representation using the URL logic described above:
```yml
A.option1:
  contents:
    (...)
```

## 4. Final configuration file
The UCP3 backend expects a final configuration file (mainly in the style of `config.yml`).
Customisations by the users over and above the configuration implied by the list of active extensions are listed.

This configuration file can contain required and suggested keyword prefixes, such that the config file can be used immediately in a new plugin (or other extension).
The GUI is responsible for checking configuration conflicts (to reduce load at runtime).

A `sparse` and `full` configuration is included in the same file. Manual changes that are done using a text editor should be done in both the `sparse` and `full` parts. The reason for this partly duplication is that the full version is easily read by the backend, while the sparse version is mainly use by the frontend (GUI), basically to remember which options were indicated by the user.

### Example
The final configuration of the example from the previous section would look like so:
```yml
active: true
specification-version: 1.0.0
config-sparse:
  other-extensions-forbidden: true
  # If there would be user customisations they would be listed here
  modules: {}
  plugins: {}
  # Which extensions were explicitly activated (from the GUI)
  load-order: [B == 0.0.1]

config-full:
  other-extensions-forbidden: true
  modules:
    A:
      config:
        option1: 
          contents:
            suggested-value: 12
  plugins:
    B: {}
  # Order in which to load the extensions
  load-order: [A == 0.0.1, B == 0.0.1]
```

# Appendix 1: Implementation details

The following steps are used when validating a setup/full configuration
1. Start with the first extension in the specified ordering of extensions, let's call it `e1`
2. This extension does not have a configuration demand (because it is the lowest level extension), but let's define three options with the following respective paths/urls: A.enabled (boolean), A.multiplier (range from 1 till 10, with a default of 2), B (boolean).
3. These options are preprocessed such that a dictionary is formed in which the keys are the urls/paths and the values are the option definitions. The extension name is prepended at this point (?). So there are now three keys: `e1.A.enabled`, `e1.A.multiplier`, and `e1.B`
4. Let's move on to the second extension, `e2`. This extension demands that `e1.A.multiplier` has a `required-min` of 2 and a `required-max` of 8 and a `suggested-value` of 4. These requirements are tested against the option definition: is it within the range as specified by the original option provider? If allowed, the Advanced Config UI takes over the new suggested value as the default value.
5. Let's move on to the third extension, `e3`. This extension demands that `e1.A.multiplier` has a `required-value` of 8. This is tested against the option, and against the specifications of `e2`. This new value is displayed in the Advanced Config UI.


There are several potentials for speedup/caching. First, a global dictionary of options can be formed that is regenerated or modified when extensions are added/removed to the list of extensions.

Second, a global dictionary can be formed in which keys are paths/urls and the values are a list of extensions that apply modifiers to this option.

Everytime the list of extensions is reordered, validation needs to occur, which means a lookup of the original option definition and a verification with other extensions lower in the hierarchy. 



# Appendix 2
The options specification is an array of elements. Each element is an instruction for the GUI on how lay out the options on the screen.

If an element is an option, it contains the `url` key.
It also contains the `contents` key with an object that contains a `value` key to specify the default value.

## Slider
A slider has a min, max, step, and decimals property.

```yaml
- url: slider1
  description: A few words about slider1
  display: slider
  contents:
    type: number
    decimals: 0
    min: 0
    max: 10
    value: 5
```

## Switch
```yaml
- url: switch1
  description: A few words about switch1
  display: switch
  contents:
    type: boolean
    value: false
```

## Choice
```yaml
- url: choice1
  description: A few words about choice1 # or use '{{choice1_description}}' to use localisation
  display: Choice
  contents:
    type: choice
    choices:
    - name: option1
      text: "This is option 1 in the dropdown"
    - name: option2
      text: "This is option 2 in the dropdown"
    value: option2 # The default value
```
