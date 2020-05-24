# Intro

Studio is our next generation app for API design, modeling, and technical writing. 

> A primary goal of Studio is to enrich, not replace, your existing workflows. It works offline, with folders and files on your computer, just like your favorite IDEs.

Read the full [Studio Docs](https://stoplight.io/p/docs/gh/stoplightio/studio).

Here is some of what it can do:

- **OpenAPI v2 and v3:** Form based design mode means you don't need to be an OpenAPI expert to get started. Studio also supports OpenAPI autocomplete in write mode, a read mode to visualize HTTP operations and models, mocking, and linting for OpenAPI v2 and v3.
- **Standalone JSON Schema Modeling:** Studio encourages you to split your models into separate files, and then makes it easy to create `$refs` between them.
- **Stoplight Flavored Markdown:** [SMD](./markdown/stoplight-flavored-markdown.md) is an optional, lightweight extension to regular markdown. It enables a few advanced features such as tabs and callouts.
- **Combine Reference and Implementation:** Since Studio works with your local filesystem, you can open up your API projects and start adding docs and designs alongside the actual implementation they are meant to describe. Once you're done, check it all into git with your favorite git client!
- **Manage Mock Servers:** Studio automatically starts local mock servers for every API defined in your project, and keeps those mock servers up to date as you change your designs.

### A Note on this Personal Space

This initial Studio project template was cloned from the [Studio Templates](https://github.com/stoplightio/studio-templates) Github repository. If you find an error, or have an idea on how to improve this getting started template, please let us know in the issues section of that repository.

We plan to add additional sections on Prism (mocking), Spectral (linting), working with the filesystem, Git, and more in the future.

This template includes a couple of example APIs (Petstore and To-dos). You can create a new project, or open another folder on your computer, by clicking the `Project Selector` dropdown in the top left of the Studio UI.