# Jami

![jami-logo](https://jami.net/assets/images/logo-jami.svg?v=8595727d35)

#### Share, freely and privately

# Introduction

Jami provides all its users a universal communication tool, autonomous, free, secure and built on a distributed architecture thus requiring no authority or central server to function.

`jami` is the cross platform client for [Jami](https://jami.net/).

For more information about the jami project, see the following:

- Main website: https://jami.net/
- Download: https://jami.net/download/
- Bug tracker: https://git.jami.net/
- Repositories: https://review.jami.net

# Getting involved

- Browse our [current issues](https://git.jami.net/savoirfairelinux/jami-client-qt/issues), or file an issue.
- IRC: #jami on libera.chat
- ML: jami@gnu.org
- Documentation: https://docs.jami.net
- Localization happens on [Transifex](https://www.transifex.com/savoirfairelinux/jami/dashboard/)
- [Our contributions propositions](https://git.jami.net/groups/savoirfairelinux/-/epics/1) or [feature requests](https://docs.jami.net/developer/feature-requests.html) asked by the community
- Packaging: Feel free to contact us

## Notes

- Coding style is managed by the clang-format and qmlformat, if you want to contribute, please use the pre-commit hook automatically installed with `./build.py --init --qt=<path/to/qt>`
- We use gerrit for our review. Please read about [working with Gerrit](https://docs.jami.net/developer/working-with-gerrit.html) if you want to submit patches.

## Build

cf [INSTALL.md](/INSTALL.md)

## Private Feeds

Below conversations, **Followed Feeds** lists subscriptions and **My Feeds** lists
the account's own Feeds, with separators between sections and the account selector
at the bottom. Use **Create my first Feed** or **+** to choose a name and avatar.
The owner manages authorized contacts individually and chooses **Read only** or
**Allow subscribers to reply**. Only the owner can start a publication; subscribers
can reply directly to publications when replies are enabled, not start new ones.

Feed chat views show publications and replies, without group creation, invitation,
membership or call events. Date separators mark changes of publication day rather
than appearing on every post or photo; replies retain their publication's grouping.
All publications are left-aligned with a generous
margin that adapts to narrow windows; the account's own avatar is not shown in
messages or their read receipts. Replies appear directly below their publication,
in chronological order and with an additional indent, rather than as standalone
messages repeating a quotation. Older publications are loaded when needed to
attach their replies. The presentation of ordinary conversations is unchanged.

**Browse**, or **Available Feeds** in the chat header's options menu, lists the
Feeds that contacts authorize this account to follow. Authorization and
subscription are separate: subscribing downloads the history, while
unsubscribing stops updates and notifications without removing authorization.
The catalogue is cached and refreshes through the owner's reachable devices;
there is no public directory. Feed settings and subscriptions follow the Jami
account across devices.

New owner publications use the normal Jami notifications, subject to account and
conversation preferences. Replies and membership events do not trigger Feed
publication notifications. Removing access prevents future access; deleting a
Feed permanently closes it. Already received copies cannot be erased remotely.
Participants and replies have the same visibility as a private group. Squads,
anonymous followers, nested reply threads and mobile Feed interfaces are not part
of this first version. Older daemons reject the new Feed conversation mode.

# License

Copyright (C) 2020-2026 Savoir-faire Linux Inc.

Jami is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.
