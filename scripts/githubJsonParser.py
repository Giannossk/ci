#!python3

import sys,json,datetime;

def get_head_sha(json_string):
    obj=json.load(json_string)
    print(obj['head']['sha'])
    
def get_base_sha(json_string):
    obj=json.load(json_string)
    print(obj['base']['sha'])
    
def get_base_ref(json_string):
    obj=json.load(json_string)
    print(obj['base']['ref'])
    
def get_state(json_string):
    obj=json.load(json_string)
    print(obj['state'])

def is_merged(json_string):
    obj=json.load(json_string)
    print(obj['merged'])

def get_commit_message(json_string):
    obj=json.load(json_string)
    print(obj['commit']['message'])

def get_commit_author(json_string):
    obj=json.load(json_string)
    print(obj['commit']['author']['name'])

def get_commit_date(json_string):
    obj=json.load(json_string)
    commit_date=obj['commit']['committer']['date']
    dt=datetime.datetime.strptime(str(commit_date), '%Y-%m-%dT%H:%M:%SZ')
    timestamp=(dt-datetime.datetime(1970,1,1)).total_seconds()
    print(int(timestamp))
    
def get_latest_build_comment(json_string):
    comments = json.load(json_string)
    for comment in reversed(comments):
        if "[ci-build]" in comment['body']:
            print(comment['body'])
            return
    print("")

def get_labels(json_string):
    obj = json.load(json_string)
    for label in (obj['labels']):
        print("'" + label['name'] + "'" + " ")
    print("")

def get_description(json_string):
    obj = json.load(json_string)
    print(obj['body'])

def get_project_url(json_string):
    obj = json.load(json_string)
    print(obj['base']['repo']['html_url'])

def get_project_name(json_string):
    obj = json.load(json_string)
    print(obj['base']['repo']['name'])
    
def get_merge_commit(json_string):
    obj = json.load(json_string)
    print(str(obj['merge_commit_sha'] or "null"))
