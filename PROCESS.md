# GitLab Contributing Process

## Purpose of describing the contributing process

Below we describe the contributing process to GitLab for two reasons. So that
contributors know what to expect from maintainers (possible responses, friendly
treatment, etc.). And so that maintainers know what to expect from contributors
(use the latest version, ensure that the issue is addressed, friendly treatment,
etc.).

- [GitLab Inc engineers should refer to the engineering workflow document](https://about.gitlab.com/handbook/engineering/workflow/)

## Common actions

### Issue triaging

Our issue triage policies are [described in our handbook]. You are very welcome
to help the GitLab team triage issues. We also organize [issue bash events] once
every quarter.

The most important thing is making sure valid issues receive feedback from the
development team. Therefore the priority is mentioning developers that can help
on those issues. Please select someone with relevant experience from
[GitLab team][team]. If there is nobody mentioned with that expertise
look in the commit history for the affected files to find someone. Avoid
mentioning the lead developer, this is the person that is least likely to give a
timely response. If the involvement of the lead developer is needed the other
core team members will mention this person.

[described in our handbook]: https://about.gitlab.com/handbook/engineering/issues/issue-triage-policies/
[issue bash events]: https://gitlab.com/gitlab-org/gitlab-ce/issues/17815

### Merge request coaching

Several people from the [GitLab team][team] are helping community members to get
their contributions accepted by meeting our [Definition of done][done].

What you can expect from them is described at https://about.gitlab.com/jobs/merge-request-coach/.

## Workflow labels

Labelling issues is described in the [GitLab Inc engineering workflow].

[GitLab Inc engineering workflow]: https://about.gitlab.com/handbook/engineering/workflow/#labelling-issues

## Assigning issues

If an issue is complex and needs the attention of a specific person, assignment is a good option but assigning issues might discourage other people from contributing to that issue. We need all the contributions we can get so this should never be discouraged. Also, an assigned person might not have time for a few weeks, so others should feel free to takeover.

## Be kind

Be kind to people trying to contribute. Be aware that people may be a non-native
English speaker, they might not understand things or they might be very
sensitive as to how you word things. Use Emoji to express your feelings (heart,
star, smile, etc.). Some good tips about code reviews can be found in our
[Code Review Guidelines].

[Code Review Guidelines]: https://docs.gitlab.com/ce/development/code_review.html

## Feature Freeze

After the 7th (Pacific Standard Time Zone) of each month, RC1 of the upcoming release is created and deployed to GitLab.com and the stable branch for this release is frozen, which means master is no longer merged into it.
Merge requests may still be merged into master during this period,
but they will go into the _next_ release, unless they are manually cherry-picked into the stable branch.
By freezing the stable branches 2 weeks prior to a release, we reduce the risk of a last minute merge request potentially breaking things.

### Between the 1st and the 7th

These types of merge requests need special consideration:

* **Large features**: a large feature is one that is highlighted in the kick-off
  and the release blogpost; typically this will have its own channel in Slack
  and a dedicated team with front-end, back-end, and UX.
* **Small features**: any other feature request.

**Large features** must be with a maintainer **by the 1st**. It's OK if they
aren't completely done, but this allows the maintainer enough time to make the
decision about whether this can make it in before the freeze. If the maintainer
doesn't think it will make it, they should inform the developers working on it
and the Product Manager responsible for the feature.

**Small features** must be with a reviewer (not necessarily maintainer) **by the
3rd**.

Most merge requests from the community do not have a specific release
target. However, if one does and falls into either of the above categories, it's
the reviewer's responsibility to manage the above communication and assignment
on behalf of the community member.

### On the 7th

Merge requests should still be complete, following the
[definition of done][done]. The single exception is documentation, and this can
only be left until after the freeze if:

* There is a follow-up issue to add documentation.
* It is assigned to the person writing documentation for this feature, and they
  are aware of it.
* It is in the correct milestone, with the ~Deliverable label.

All Community Edition merge requests from GitLab team members merged on the
freeze date (the 7th) should have a corresponding Enterprise Edition merge
request, even if there are no conflicts. This is to reduce the size of the
subsequent EE merge, as we often merge a lot to CE on the release date. For more
information, see
[limit conflicts with EE when developing on CE][limit_ee_conflicts].

### Between the 7th and the 22nd

Once the stable branch is frozen, only fixes for regressions (bugs introduced in that same release)
and security issues will be cherry-picked into the stable branch.
Any merge requests cherry-picked into the stable branch for a previous release will also be picked into the latest stable branch.
These fixes will be released in the next RC (before the 22nd) or patch release (after the 22nd).

If you think a merge request should go into the upcoming release even though it does not meet these requirements,
you can ask for an exception to be made. Exceptions require sign-off from 3 people besides the developer:

1. a Release Manager
2. an Engineering Lead
3. an Engineering Director, the VP of Engineering, or the CTO

You can find who is who on the [team page](https://about.gitlab.com/team/).

Whether an exception is made is determined by weighing the benefit and urgency of the change
(how important it is to the company that this is released _right now_ instead of in a month)
against the potential negative impact
(things breaking without enough time to comfortably find and fix them before the release on the 22nd).
When in doubt, we err on the side of _not_ cherry-picking.

For example, it is likely that an exception will be made for a trivial 1-5 line performance improvement
(e.g. adding a database index or adding `includes` to a query), but not for a new feature, no matter how relatively small or thoroughly tested.

During the feature freeze all merge requests that are meant to go into the upcoming
release should have the correct milestone assigned _and_ have the label
~"Pick into Stable" set, so that release managers can find and pick them.
Merge requests without a milestone and this label will
not be merged into any stable branches.

## Copy & paste responses

### Improperly formatted issue

Thanks for the issue report. Please reformat your issue to conform to the [contributing guidelines](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#issue-tracker-guidelines).

### Issue report for old version

Thanks for the issue report but we only support issues for the latest stable version of GitLab. I'm closing this issue but if you still experience this problem in the latest stable version, please open a new issue (but also reference the old issue(s)). Make sure to also include the necessary debugging information conforming to the issue tracker guidelines found in our [contributing guidelines](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#issue-tracker-guidelines).

### Support requests and configuration questions

Thanks for your interest in GitLab. We don't use the issue tracker for support
requests and configuration questions. Please check our
[getting help](https://about.gitlab.com/getting-help/) page to see all of the available
support options. Also, have a look at the [contribution guidelines](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md)
for more information.

### Code format

Please use \`\`\` to format console output, logs, and code as it's very hard to read otherwise.

### Issue fixed in newer version

Thanks for the issue report. This issue has already been fixed in newer versions of GitLab. Due to the size of this project and our limited resources we are only able to support the latest stable release as outlined in our [contributing guidelines](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#issue-tracker). In order to get this bug fix and enjoy many new features please [upgrade](https://gitlab.com/gitlab-org/gitlab-ce/tree/master/doc/update). If you still experience issues at that time please open a new issue following our issue tracker guidelines found in the [contributing guidelines](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#issue-tracker-guidelines).

### Improperly formatted merge request

Thanks for your interest in improving the GitLab codebase! Please update your merge request according to the [contributing guidelines](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#pull-request-guidelines).

### Inactivity close of an issue

It's been at least 2 weeks (and a new release) since we heard from you. I'm closing this issue but if you still experience this problem, please open a new issue (but also reference the old issue(s)). Make sure to also include the necessary debugging information conforming to the issue tracker guidelines found in our [contributing guidelines](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#issue-tracker-guidelines).

### Inactivity close of a merge request

This merge request has been closed because a request for more information has not been reacted to for more than 2 weeks. If you respond and conform to the merge request guidelines in our [contributing guidelines](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#pull-requests) we will reopen this merge request.

### Accepting merge requests

Is there an issue on the
[issue tracker](https://gitlab.com/gitlab-org/gitlab-ce/issues) that is
similar to this? Could you please link it here?
Please be aware that new functionality that is not marked
[accepting merge requests](https://gitlab.com/gitlab-org/gitlab-ce/issues?milestone_id=&scope=all&sort=created_desc&state=opened&utf8=%E2%9C%93&assignee_id=&author_id=&milestone_title=&label_name=Accepting+Merge+Requests)
might not make it into GitLab.

### Only accepting merge requests with green tests

We can only accept a merge request if all the tests are green. I've just
restarted the build. When the tests are still not passing after this restart and
you're sure that is does not have anything to do with your code changes, please
rebase with master to see if that solves the issue.

### Closing down the issue tracker on GitHub

We are currently in the process of closing down the issue tracker on GitHub, to
prevent duplication with the GitLab.com issue tracker.
Since this is an older issue I'll be closing this for now. If you think this is
still an issue I encourage you to open it on the [GitLab.com issue tracker](https://gitlab.com/gitlab-org/gitlab-ce/issues).

[team]: https://about.gitlab.com/team/
[contribution acceptance criteria]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#contribution-acceptance-criteria
["Implement design & UI elements" guidelines]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#implement-design-ui-elements
[Thoughtbot code review guide]: https://github.com/thoughtbot/guides/tree/master/code-review
[done]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md#definition-of-done
[limit_ee_conflicts]: https://docs.gitlab.com/ce/development/limit_ee_conflicts.html
