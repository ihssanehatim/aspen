# Aspen

Aspen is a simple markup language that transforms simple narrative information into rich graph data for use in Neo4j.

To put it another way, Aspen transforms narrative text to Cypher, specifically for use in creating graph data.

In short, Aspen transforms this:

```cypher
(Matt) [knows] (Brianna)
```

into this:

```cypher
MERGE (:Person { name: "Matt" })-[:KNOWS]->(:Person { name: "Brianna" })
```

(It's only slightly more complicated than that.)


## Graphs4Good

Have you registered with [Graphs4Good](http://graphs4good.me/) yet?

> This new program aims to showcase – and then support, encourage and connect others to – graph-powered projects that effect positive social change, uphold democratic principles and take on some of the world's toughest challenges. [~ graphs4good.me](http://graphs4good.me/)

Aspen's purpose is to enable graph data creation for people who need the insights of graph databases but aren't developers and/or don't have the time to learn it.

The technology itself may be neutral, but it was inspired by a conflict resolution / peacebuilding exercise, and the team behind it wants to see it deployed in situations where developers and non-developers alike could use it to further peacebuilding efforts and other positive social change.

Admittedly, Aspen can't bring graphs to non-developers on its own, but it's trying to contribute to solutions.


## Installation

[Help improve the installation process, usage instructions, or tutorial.](https://github.com/beechnut/aspen/issues/2)

#### Prerequisites

The following are needed to install Aspen:

* **Ruby, version 2.6** or newer.
* **Bundler** - Run `gem install bundler` in your terminal window to set up bundler after Ruby is already installed

#### Installation

1. Fork this repository.
2. Clone your forked repository by running `git clone git@github.com:YOUR_USERNAME/aspen.git` in your terminal window.
3. Navigate to the cloned repository by running `cd aspen`.
4. Run `bundle install` to install Aspen's dependencies.



## Usage

### Command-Line Interface

#### Compiling a file

Once you write an Aspen file, compile it to Cypher (`.cql`) by running:

```sh
$ bundle exec bin/aspen compile /path/to/an-aspen-file.aspen
```

This will generate a file Cypher file in the same folder, at `path/to/file.cql`.

#### Watching a file or folder

You may want to "watch" a file or folder of Aspen files for changes, and have them recompile to Cypher (`.cql`) every time you save a file.

```sh
$ bundle exec bin/aspen watch /path/containing/aspen/files
```

If you want the data to be published to a Neo4j database, run the command with the `--database`  or `-d` option, with the URL to a Neo4j instance. (This currently only supports HTTP.)

```sh
$ bundle exec bin/aspen watch /path/containing/aspen/files -d http://user:pass@localhost:port
```

If the database you're connecting to is a playground instance, retaining your data doesn't matter, and you just want to use Aspen to iterate on your data & data model, use the `--drop` option.

__Danger!__ This will delete all of your data, every time you save a file.

```sh
$ bundle exec bin/aspen watch /path/containing/aspen/files -d http://user:pass@localhost:port --drop
```

Press Ctrl+C to quit the watcher.

### Aspen Tutorial

[Help improve this tutorial.](https://github.com/beechnut/aspen/issues/1)

Before reading this, make sure you know basic Cypher. I recommend you be able to comfortably write statements that create multiple nodes and edges, as well as statements that can query multiple nodes and edges. (If you don't, some of the concepts might not land.)

Need an introduction to Cypher? [Get the Graph Databases ebook.](https://neo4j.com/graph-databases-book/)

Need a refresher? [See the Cypher manual.](https://neo4j.com/docs/cypher-manual/current/)


#### Parts of an Aspen file

There are two important parts of any Aspen file: a __narrative__ and a __discourse__.

A __narrative__ is a description of data that records facts, observations, and perceptions about relationships. For example, in an Aspen file, we'll describe a relationship between two people like this: `(Matt) [knows] (Brianna)`.

A __discourse__ is a way of speaking or writing about a subject. Aspen doesn't automatically know what `(Matt) [knows] (Brianna)` means, so we have to tell it. Because they're wrapped in parentheses, Aspen knows that Matt and Brianna will be nodes, but it doesn't know enough to generate Cypher just from this line.

In an Aspen file, the discourse is written at the top, and the narrative is written at the bottom, __always__ split by a line of just four dashes: `----`.

If you're coming from a software development background, you can think of the discourse as a sort of configuration that will be used to build the Cypher file that results from the Aspen narrative.

Here's an example of an Aspen file, with discourse and narrative sections marked:

```aspen
# Discourse
default Person, name
----
# Narrative
(Matt) [knows] (Brianna).
(Eliza) [knows] (Brianna).
(Matt) [knows] (Eliza).
```

If the concepts of discourse and narrative aren't fully clear right now, that's okay—keep going. The rest of the tutorial should shed light on them. Also, this README was written pretty quickly, and if you have suggestions, please [contribute](https://github.com/beechnut/aspen/issues/1)—your feedback will be well-received and appreciated!

[Help improve this tutorial.](https://github.com/beechnut/aspen/issues/1)

#### Syntax

The simplest case for using Aspen is a simple relationship between two people.

> Matt knows Brianna.

Aspen doesn't know which of these are nodes and which are edges, so we have to tell it by adding parentheses `()` to indicate nodes and square brackets `[]` to indicate edges. This should look familiar—these conventions are intentionally the same as Cypher.

```aspen
(Matt) [knows] (Brianna).
```

Now that that's out of the way, let's think about what we can conclude from this statement:

- The strings of text `"Matt"` and `"Brianna"` are names.
- Matt and Brianna are people, so they should have a `:Person` label in Cypher.
- If Matt knows Brianna, Brianna knows Matt as well, so the relationship "knows" is reciprocal.

However, Aspen doesn't know any of this automatically!

So, we need to tell Aspen:

- What attribute to assign the text `"Matt"` and `"Brianna"`
- What kind of labels to apply to the nodes
- That the relationship "knows" is a reciprocal (or "two-way", or "undirected") relationship

##### Default label and attribute name

First, we need to tell Aspen that, when it encounters a simple or "short form" node like `(Matt)`, that it should assume it's a person, and that the text in parentheses is the name of the person.

To do this, let's add a `default` line to the discourse section of the file, up at the top. This directs Aspen to assign unlabeled nodes a `:Person` label, and that the text should be assigned to the Person's `name` attribute.

```aspen
 # Discourse
default Person, name
----
# Narrative
(Matt) [knows] (Brianna).
```

When we run this, we get this Cypher:

```cypher
MERGE (person_matt:Person { name: "Matt" })
MERGE (person_brianna:Person { name: "Brianna" })

MERGE (person_matt)-[:KNOWS]->(person_brianna)
;
```

##### Making relationships reciprocal

Take a look at the arrow—it's pointing from Matt to Brianna, suggesting that Matt knows Brianna but Brianna doesn't know Matt.

However, we want the relationship "knows" to be reciprocal, because if Matt knows Brianna, we can assume that Brianna knows Matt.

> A note on reciprocal relationships:
>
> In Neo4j, the convention is for reciprocal (also known as bidirectional or undirected) relationships to be represented by a directional relationship. [Read more at GraphAware](https://graphaware.com/neo4j/2013/10/11/neo4j-bidirectional-relationships.html).
>
> However, we want our resulting Cypher to show a reciprocal relationship so we can read the Cypher and understand the intent of the code.

If we wanted to show that we intend to create a reciprocal relationship, we'd write Cypher for "Matt knows Brianna" as follows. Notice that there's no arrowhead—the relationship is "undirected".

```cypher
MERGE (person_matt)-[:KNOWS]-(person_brianna)
```

To get this reciprocality in Aspen, we list all the reciprocal relationships after the keyword `reciprocal`:

```aspen
# Discourse
default Person, name
reciprocal knows
----
# Narrative
(Matt) [knows] (Brianna).
```

This gives us the undirected relationship in Cypher that we want!

If we had multiple reciprocal relationships, we'd write

```aspen
reciprocal knows, is friends with, is married to
```

This would ensure that `[:KNOWS]`, `[:IS_FRIENDS_WITH]`, and `[:IS_MARRIED_TO]` would all be encoded as undirected relationships.


##### How to write nodes

There are three ways to write nodes.

- `(Matt)` - short form: requires a `default` line in the discourse
- `(Person, Matt)` - default attribute form: requires a `default_attribute` line in the discourse
- `(Person { name: "Matt" })` - full form or Cypher form: self-contained, requires nothing in the discourse

> At present, the discourse still complains if nothing is set. [Help fix this issue.](https://github.com/beechnut/aspen/issues/4)

If you need a node with multiple attributes, you can write:

```cypher
(Person { name: 'Matt', state: 'MA', age: 31 })
```

Notice how there's no preceding `:` in front of `Person` in Aspen, but there is in Cypher.

But let's review how to handle when you have another node type (aka label) in your data, and you want to keep it short, using "default attribute form".

Let's say we want to represent an Employer, and the employer's name is UMass Boston.

```aspen
default Person, name
----
...
(Matt) [works at] (Employer, UMass Boston)
```

Note how this node starts with a label, followed by a comma, followed by content to be assigned to an attribute. In order to tell Aspen to assign the text "UMass Boston" to an attribute called `company_name`, we add a `default_attribute` statement to the discourse section.

```
# Discourse
default Person, name
default_attribute Employer, company_name
----
# Narrative
(Matt) [works at] (Employer, UMass Boston)
```

The `default_attribute` line tells Aspen that when we encounter a node in default-attribute form, that it should assign the content for a node beginning  with `Employer` to `company_name`.

Let's go over the differences between `default` and `default_attribute`.

The `default` directive will catch any unlabeled nodes, like `(Matt)`, and label them. It will then assign the text inside the parentheses, `"Matt"`, to the attribute given as the default. If the default is `Person, name`, it will create a Person node with name "Matt".

If we had a node like `(UMass Boston)`, it would result in the creation of a Person node with a name "UMass Boston":

```cypher
/* This is not what we wanted. */
(:Person { name: "UMass Boston" })
```

The `default_attribute` directive will assign any nodes with the given label to the given attribute. So Aspen like `(Employer, ACME Corp.)` will create a node like

```cypher
(:Employer { name: "ACME Corp." })
```


The whole code all together is:

```
# Discourse
default Person, name
default_attribute Employer, company_name
reciprocal knows
----
# Narrative
(Matt) [knows] (Brianna).
(Matt) [works at] (Employer, UMass Boston).
```

The Cypher produced generates the reciprocal "knows" relationship, and the one-way employment relationship.

```cypher
MERGE (person_matt:Person { name: "Matt" })
MERGE (person_brianna:Person { name: "Brianna" })
MERGE (employer_umass_boston:Employer { company_name: "UMass Boston" })

MERGE (person_matt)-[:KNOWS]-(person_brianna)
MERGE (person_matt)-[:WORKS_AT]->(employer_umass_boston)
;
```

> A note about attribute types:
>
> One known issue is that `default` and `default_attribute` auto-type the attributes they're given, and try to make them either a string or number. So, if you pass a Massachusetts zip code like `02111` into a node in either short form or default attribute form, it will become integer `2111`.
>
> As a Massachusetts resident, I vowed never to let this happen in my software, so I intend to address this soon.
>
> [Help fix this issue.](https://github.com/beechnut/aspen/issues/9)

#### Custom Grammars

Let's say you have a data model that tracks donations to local political candidates. Being the adept data modeler you are, you create a model that models donations as nodes, with relationships between the donor and donation, and between the recipient and donation.

```cypher
(:Person)-[:GAVE_DONATION]->(:Donation)<-[:RECEIVED_DONATION]-(:Person)
```

To write this in vanilla Aspen, you'd write:

```
default Person, name
default_atttibute Donation, amount
----
(Matt) [gave donation] (Donation, 20.00).
(Hélène) [received donation] (Donation, 20.00).
```

You may already be seeing some issues with this, like:

- How does the language know whether those two donations are the same donation, or different donations of the same amount?
- What currency is that? We can assume it's USD from context, but it's not self-evident.
- It takes two lines to express a single concept, which is counter to Aspen's goal of producing data efficiently.

To solve all of these issues, we can define custom grammars.

__Custom grammars__ define sentences and assign them to Cypher statements. Once we define a custom grammar, we can write a simple sentence—with no parentheses or brackets!—and it will populate a Cypher statement.

Let's say we want to be able to write "Matt donated $20 to Hélène.", and have it map to a Cypher statement.

```
# Discourse
default_attribute Person, name

match
  Matt donated $20 to Hélène.
to
  (:Person { name: "Matt" })-[:GAVE_DONATION]->(:Donation { amount: 20 })<-[:RECEIVED_DONATION]-(:Person { name: "Hélène" })
end
----
# Narrative
Matt donated $20 to Hélène.
```

#### Adding matchers for nodes

The above grammar gives us the *exact* statement we want, but next we want to generalize it so we can write, "Sarah donated  $30 to Sumbul". We need to set variables in both the `match` and `to` sections.

First, let's replace the donor and recipient. These will both be `Person`s, so we'll write:

```
default Person, name

match
  (Person a) donated $20 to (Person b).
to
  {{{a}}}-[:GAVE_DONATION]->(:Donation { amount: 20 })<-[:RECEIVED_DONATION]-{{{b}}}
end
----
Matt donated $20 to Hélène.
Sarah donated $30 to Sumbul.
```

We've changed two things here. (We still have to do the dollar amount. That will be the following step.)

First, we replaced the literal names of "Matt" and "Hélène" with __matchers__ that will take the text of a sentence and assign it to variables `a` and `b`.

Second, we use the variables `a` and `b` in the template. To do this, we removed the Cypher and the parentheses, and surrounded each variable with triple curly braces `{{{}}}`, to indicate that they are

> The templates—in the `to` section—use a templating language called Mustache. If you've ever used Mustache, you've probably used double braces like `{{variable}}`. We need triple braces in Aspen because Mustache escapes characters to be HTML-safe, which is a problem because Cypher needs those characters. If you accidentally use double-braces, you'll see nodes like:
>
> `(:Person, { name: &quot;Matt&quot; })`
>
> Not ideal! So, triple braces it is.

When we feed this custom grammar with the sentence "Matt donated $20 to Hélène.", the data behind the scenes looks sort of like this:

```ruby
{
  "a" => (:Person, { name: "Matt" }),
  "b" => (:Person, { name: "Hélène" }),
}
```

> How does it know the text should be the `name` attribute? It's because we told Aspen the default attribute for Person is `name`. But, if you wanted to specify different attributes, you could write a Person node in default attribute form or full form, like:
>
> `(Person, Matt) donated $20 to (Person { name: "Matt", age: 31 }).`
>
> Your choice!

When we take this template

```cypher
...
to
  {{{a}}}-[:GAVE_DONATION]->(:Donation { amount: 20 })<-[:RECEIVED_DONATION]-{{{b}}}
```

and populate it with the above data, we get the Cypher we're aiming for:

```cypher
/* Simplified slightly for demonstration purposes */

(:Person { name: "Matt" })-[:GAVE_DONATION]->(:Donation { amount: 20 })<-[:RECEIVED_DONATION]-(:Person { name: "Hélène" })
```

#### Adding matchers for other information

We still have to set the amount of the donation as a variable. If we left it as is, every donation would be $20 forever!
```
...

match
  (Person a) donated $(numeric dollar_amount) to (Person b).
to
  {{{a}}}-[:GAVE_DONATION]->(:Donation { amount: {{{dollar_amount}}} })<-[:RECEIVED_DONATION]-{{{b}}}
end
...
```

Okay, so we've added the matcher `(numeric dollar_amount)`, and used the variable in the template.

#### Types of matchers

Aspen accepts three different types of matchers: numeric, string, and nodes. We've already seen nodes.

__Node matchers__  we've already used, and they come in the form of `(Label variable_name)`. If you type any word starting with an uppercase letter, that's the label that will be applied. Node matchers capture nodes in all three forms, so write them however you'd like—full form, default-attribute form, or short form!

__Numeric matchers__ will match typical (US) formats of numbers, including:

- `1` (integer)
- `0.000001` (float)
- `100,000,000.00` (float)

For convenience, any numeric type (even if it has commas!) will be converted to numbers. Whole numbers will be converted to integers, and anything with a decimal point will be converted to floats.

__String matchers__ will match anything in double-quotes. (Please don't use single quotes, as Aspen doesn't support them yet. [Help fix this issue.](https://github.com/beechnut/aspen/issues/6))

At the moment, if you have a string matcher like

```
Matt works as a (string job_position) at UMass Boston.
```

then make sure to write the value for `job_position` in quotes, like

```
Matt works as a "research assistant" at UMass Boston.
```

If you don't, it won't match!

The quotes read as sarcastic, so we want to change this soon! [(Help fix this issue.)](https://github.com/beechnut/aspen/issues/5)

#### Finishing our custom grammar

Let's see the whole file and add some more lines that this grammar can match, as well as some vanilla Aspen.

Statements that match custom grammars don't need brackets and parentheses, but vanilla Aspen—Aspen that won't match custom grammars—always do.

```
default Person, name
reciprocal knows

match
  (Person a) donated $(numeric dollar_amount) to (Person b).
  (Person a) gave (Person b) $(numeric dollar_amount).
  (Person a) gave a $(numeric dollar_amount) donation to (Person b).
to
  {{{a}}}-[:GAVE_DONATION]->(:Donation { amount: {{{dollar_amount}}} })<-[:RECEIVED_DONATION]-{{{b}}}
end
----

Matt donated $20 to Hélène.
Sarah donated $30 to Sumbul.
(Matt) [voted for] (Sumbul).
(Sarah) [knows] (Hélène).
(Matt) [knows] (Sarah).

Becky gave Mayor Joe $20.
Yael gave a $20 donation to Sam.
(Becky) [volunteered for] (Mayor Joe).
(Yael) [knows] (Becky).
(Becky) [knows] (Sam).
(Becky) [knows] (Matt).
```

> We didn't show this, but you can also have more than one `match..to..end` block to add more grammars. They'll try to match in the order in which they are defined in the file.)

This will produce a wealth of Cypher. We're leaving it here in full so you can compare it to the Aspen.

```
MERGE (person_matt:Person { name: "Matt" })
MERGE (person_helene:Person { name: "Hélène" })
MERGE (person_sarah:Person { name: "Sarah" })
MERGE (person_sumbul:Person { name: "Sumbul" })
MERGE (person_becky:Person { name: "Becky" })
MERGE (person_mayor_joe:Person { name: "Mayor Joe" })
MERGE (person_yael:Person { name: "Yael" })
MERGE (person_sam:Person { name: "Sam" })

MERGE (person_matt)-[:GAVE_DONATION]->(:Donation { amount: 20 })<-[:RECEIVED_DONATION]-(person_helene)
MERGE (person_sarah)-[:GAVE_DONATION]->(:Donation { amount: 30 })<-[:RECEIVED_DONATION]-(person_sumbul)
MERGE (person_matt)-[:VOTED_FOR]->(person_sumbul)
MERGE (person_sarah)-[:KNOWS]-(person_helene)
MERGE (person_matt)-[:KNOWS]-(person_sarah)
MERGE (person_becky)-[:GAVE_DONATION]->(:Donation { amount: 20 })<-[:RECEIVED_DONATION]-(person_mayor_joe)
MERGE (person_yael)-[:GAVE_DONATION]->(:Donation { amount: 20 })<-[:RECEIVED_DONATION]-(person_sam)
MERGE (person_becky)-[:VOLUNTEERED_FOR]->(person_mayor_joe)
MERGE (person_yael)-[:KNOWS]-(person_becky)
MERGE (person_becky)-[:KNOWS]-(person_sam)
MERGE (person_becky)-[:KNOWS]-(person_matt)
;
```

That's the end of the tutorial for now! Do you have more questions? Is something unclear? [Comment here or contribute your suggestions!](https://github.com/beechnut/aspen/issues/1)


## Background

### Problem Statement

@beechnut, the lead developer of Aspen, attempted to model a simple conflict scenario in Neo4j's language Cypher, but found it took significantly longer than expected. He ran into numerous errors because it wasn't obvious how to construct nodes and edges through simple statements.

It is a given that writing Cypher directly is time-consuming and error-prone, especially for beginners. This is not a criticism of Cypher—we love Cypher and think it's extremely-well designed. Aspen is just attempting to make it easier to generate data by hand.

### Hypotheses

We assume that most graph data is constructed through a myriad of ways besides free-form text. We *also* assume that if the tools existed to support converting semi-structured text to graph data, these tools would find wide use in a variety of fields.

We believe that graph databases and graph algorithms can provide deep insights into complex systems, and that people would find value in converting simple narrative descriptions into graph data.

## Roadmap

- Aspen Notebook - live connection between Aspen and a playground Neo4j instance, so you can type Aspen on the left and see the visual graph on the right
- Schema and attribute protections - so a typo doesn't mess up your data model
- Short nicknames & attribute uniqueness - so you can avoid accidental data duplication when "Matt" and "Matt Cloyd" are the same person
- Custom attribute handling functions - if your default nodes could either be a first name or a full name, switch between attributes
- Aspen Notebook publishing - publish data to a development/test/production Neo4j instance (and perhaps view diffs)
- Two-way conversion between Neo4j data and Aspen

Are you interested in seeing any of these features come to life? If so, [get in touch](mailto:cloyd.matt@gmail.com) so we can talk about feature sponsorship!


## Code of Conduct

We expect that anyone working on this project will be good and kind to each other. We're developing software about relationships, and anyone who works on this project is expected to have healthy relating skills.

Everyone interacting in the Aspen project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/beechnut/aspen/blob/master/CODE_OF_CONDUCT.md).

The full Code of Conduct is available at CODE_OF_CONDUCT.md.


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/beechnut/aspen. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/beechnut/aspen/blob/master/CODE_OF_CONDUCT.md).

If you'd like to see Aspen grow, please [get in touch](mailto:cloyd.matt@gmail.com), whether you're a developer, user, or potential sponsor. We have ideas on ways to grow Aspen, and we need your help to do so, whatever form that help takes. We'd love to invite a corporate sponsor to help inform and sustain Aspen's growth and development.



## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

