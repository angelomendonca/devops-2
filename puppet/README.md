List Server
======
in  our current architecture, we have many server managed by an architecture Puppet Master-Agent. 
Due to autoscaling and dynamic server role behavior, i wrote this script that help everyone of our team to be up-to-date of all server ccurrenlty running in every environment.

Requirements
---
The script assumes :

- that you have Ruby installed  with the following gem 

    - 'net/http'
    - 'net/https'
    - 'net/ping'
    - 'uri'
    - 'filecache'
    - 'colorize'
    - 'mongo'

- that your server naming convention is as follow : 

    `environment-role-uniq-identifier-string`

- that you have this facts declared on your puppet : 

   - role
   - cronMaster

- that you have replicaSets matching the role 'mongodb'

Otherwise you are free to customize it as you whish

Features
---
The script provides a 8 hour cache after the first  run, putting in evidence the mongo primary server fqdn and cronMaster webserver.

Usage
---
The script accept 2 parameters: 

- first : environment
- second : role   (optional)

The  output will colorize the cronMaster and primary mongo server for every replicaSet

How to contribute
---
File an issue in the repository, describing the contribution you'd like to make.
This will help us to get you started on the right foot.
Fork the project in your account and create a new branch: your-great-feature.
Commit your changes in that branch.
Open a pull request, and reference the initial issue in the pull request message.
