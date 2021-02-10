# Databricks CSV Query

Assignment description:
https://docs.google.com/document/d/10yqL3IIQ94-BjLOWMNEr4lKC68G2g-EgUroIRyCs7E0/edit

## Installation

Requirements:
- Ruby: 2.7
- ZeroMQ: 4

```zsh
brew install zmq  # Or you favorite Linux package

bundle install  # Install Ruby dependencies. Most of them are for code linting
```

Setup `settings.yml` with the ZeroMQ hosts.

## Execution

The implementation consists for 3 different services which interact with each
other using ZeroMQ.

- The Client
- The Server
- The Storage

You can run these services in 3 separate tabs:

```zsh
ruby storage/storage.rb
ruby server/server.rb
ruby client/client.rb  # CLI
```

## Testing

```sh
rspec
```

## Code Architecture

You can check the `system_design.png` image to get an idea of the currenct
architecture.

### Assumptions

For the current implementation the following generic assumptions have been made:

- All data can be fit in the memory.
- The scale of the system does not require a multi-threaded solution behind a
  load balancer. However, a basic decoupling has been made which will allow for
  easier scalability refactorings to be done in the future.

I will dive into more details about the opportunities we have in each service.

### The Client Service

The Client service is an agnostic Readline loop that simply forwards whatever
the user enters to the Queuing mechanism, which in our case is ZeroMQ.

Since the Client is decoupled for the rest of the system, it can be a CLI or a
GUI or whatever Interface we can think of.

By changing a few things about the Queuing mechanism, we can easily support
multiple Clients connected at the same time. Re-trial of failed queries, etc.

### The Storage Service

The Storage service is also decoupled from the rest of the system and is
communicating with the Server via a Messaging Queue to provide to requested
data.

The Storage itself is agnostic regarding the usage of its data. Its purpose is
to provide an interface to the Queue for fetching content.

The content can be present in the File System, as in our case, or even on the
Web.

The Storage has a simple FIFO caching eviction policy to avoid repetitive I/O.
This can be converted to an LRU cache.

The Storage could function as a CDN and there could be multiple instance of the
service behind a load balancer.

The current implementation does not mutate the saved data. If such actions are
desirable, a locking mechanism needs to be implemented.

The service does not implement any runtime constraints to halt the reading
process of big files.

### The Server Service

The Server is the service which combines the Client input and the Storage data
to produce the desired results.

It uses a Messaging queue to communicate with the other two services.

The Server contains a Query parser which tokenizes the user's input. Currently,
there is no optimization being done on the query, such as removing contiguous
`ORDERBY` operations. By using a stronger language, such as SQL, we could of
course express more complex queries.

The Server also contains the Table model. This model is the one communicating
with the Storage service and it actually calculates the results. We could use a
lazy evaluation of the queries, so that queries like `FROM ... SELECT ... TAKE
5` won't have to operate on the whole dataset.

Indexing would allow us to optimize the queries even more. This would probably
interfere with the Storage service.

We can easily scale the Server service by adding a Thread pool to work on the
Client data concurrently and also have multiple Server instances.
