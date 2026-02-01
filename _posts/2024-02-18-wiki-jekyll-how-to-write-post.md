---
title: "How to write a Jekyll post"
article_type: post
date: 2024-02-18 23:10:00 +0200
categories: [Blogging, Tutorial]
tags: [writing]
render_with_liquid: false
---

This guide walks through writing a post with the _Chirpy_ template. Even if you've used Jekyll before, it's worth a skim since some features need specific variables.

## Naming and Path

Create `YYYY-MM-DD-TITLE.EXTENSION`{: .filepath} in `_posts`{: .filepath} at the root. `EXTENSION`{: .filepath} must be `md`{: .filepath} or `markdown`{: .filepath}. To save time, use [`Jekyll-Compose`](https://github.com/jekyll/jekyll-compose).



## Fonts

Front image: Coolvetica RG, size 36 in paint.net. Export to WebP at 1200x630.



## Media conversion

Convert PNG files to WebP for this site:

```bash
sudo apt install webp 
sudo pacman -Syu webp
```

To convert an image to WebP, `-q` sets output quality and `-o` sets the output file.

```bash
cwebp -q 85 myimg.png -o myimg.webp
```

Custom script to convert all `.png` files to `.webp` in a folder:

```bash
#!/bin/bash
usage() {
    echo "Usage: $0 [-q quality]"
    echo "  -q quality : Set the quality for the webp conversion (default is 85)"
    exit 1
}

quality=85

while getopts "q:" opt; do
    case ${opt} in
        q )
            quality=$OPTARG
            ;;
        \? )
            usage
            ;;
    esac
done

current_dir=$(basename "$PWD")

new_dir="${current_dir}_conv"

mkdir -p "$new_dir"

for file in *.png; do
    if [ -f "$file" ]; then
        new_file="${new_dir}/$(basename "${file%.png}.webp")"
        cwebp -q "$quality" "$file" -o "$new_file"
        echo "Converted $file to $new_file with quality $quality"
    fi
done

for file in *.jpg *.jpeg; do
    if [ -f "$file" ]; then
        new_file="${new_dir}/$(basename "${file%.*}.webp")"
        cwebp -q "$quality" "$file" -o "$new_file"
        echo "Converted $file to $new_file with quality $quality"
    fi
done

echo "Conversion complete!"
exit 0
```
## Front Matter

Basically, you need to fill the [Front Matter](https://jekyllrb.com/docs/front-matter/) as below at the top of the post:

```yaml
---
title: TITLE
date: YYYY-MM-DD HH:MM:SS +/-TTTT
categories: [TOP_CATEGORIE, SUB_CATEGORIE]
tags: [TAG]     # TAG names should always be lowercase
---
```

> The posts' _layout_ has been set to `post` by default, so there is no need to add the variable _layout_ in the Front Matter block.
{: .prompt-tip }

### Timezone of Date

To record the release date accurately, set `timezone` in `_config.yml`{: .filepath} and include the post's timezone in `date` in the Front Matter. Format: `+/-TTTT`, e.g., `+0800`.

### Categories and Tags

`categories` should have up to two items; `tags` can have as many as you like. For example:

```yaml
---
categories: [Animal, Insect]
tags: [bee]
---
```

### Author Information

Author info usually comes from `social.name` and the first entry in `social.links`. If you want to override it, add author data in `_data/authors.yml` (create it if it doesn't exist):

```yaml
<author_id>:
  name: <full name>
  twitter: <twitter_of_author>
  url: <homepage_of_author>
```
{: file="_data/authors.yml" }

Then use `author` for a single entry or `authors` for multiple:

```yaml
---
author: <author_id>                     # for single entry
# or
authors: [<author1_id>, <author2_id>]   # for multiple entries
---
```

The `author` key can also point to multiple entries.

> Reading author info from `_data/authors.yml`{: .filepath } adds the `twitter:creator` meta tag, which enriches [Twitter Cards](https://developer.twitter.com/en/docs/twitter-for-websites/cards/guides/getting-started#card-and-content-attribution) and helps SEO.
{: .prompt-info }

### Post Description

By default, the first words of the post show up on the home page, in _Further Reading_, and in the RSS feed. To override the auto-generated description, set `description` in the Front Matter:

```yaml
---
description: Short summary of the post.
---
```

That `description` also appears under the post title on the post page.

## Table of Contents

By default, the **T**able **o**f **C**ontents (TOC) appears on the right. To turn it off globally, set `toc` to `false` in `_config.yml`{: .filepath}. To disable it for one post, add this to its Front Matter:

```yaml
---
toc: false
---
```

## Comments

Set the global comments switch with `comments.active` in `_config.yml`{: .filepath}. Once you pick a system, comments are on for all posts.

To turn off comments for a single post, add this to its Front Matter:

```yaml
---
comments: false
---
```

## Mathematics

We use [**MathJax**][mathjax] for math. It's off by default for performance, but you can enable it with:

[mathjax]: https://www.mathjax.org/

```yaml
---
math: true
---
```

After enabling math, use these patterns:

- **Block math**: `$$ math $$` with **mandatory** blank lines before and after `$$`
  - **Equation numbering**: `$$\begin{equation} math \end{equation}$$`
  - **Reference numbering**: `\label{eq:label_name}` in the block and `\eqref{eq:label_name}` inline
- **Inline math** (in lines): `$$ math $$` with no blank lines before or after
- **Inline math** (in lists): `\$$ math $$`

```markdown
<!-- Block math, keep all blank lines -->

$$
LaTeX_math_expression
$$

<!-- Equation numbering, keep all blank lines  -->

$$
\begin{equation}
  LaTeX_math_expression
  \label{eq:label_name}
\end{equation}
$$

Can be referenced as \eqref{eq:label_name}.

<!-- Inline math in lines, NO blank lines -->

"Lorem ipsum dolor sit amet, $$ LaTeX_math_expression $$ consectetur adipiscing elit."

<!-- Inline math in lists, escape the first `$` -->

1. \$$ LaTeX_math_expression $$
2. \$$ LaTeX_math_expression $$
3. \$$ LaTeX_math_expression $$
```

> Starting with `v7.0.0`, **MathJax** options live in `assets/js/data/mathjax.js`{: .filepath }. Adjust them as needed, e.g., add [extensions][mathjax-exts].  
> If you're building with `chirpy-starter`, copy that file from the gem install directory (see `bundle info --path jekyll-theme-chirpy`) into your repo.
{: .prompt-tip }

[mathjax-exts]: https://docs.mathjax.org/en/latest/input/tex/extensions/index.html

## Mermaid

[**Mermaid**](https://github.com/mermaid-js/mermaid) is great for diagrams. To enable it for a post, add this to the YAML block:

```yaml
---
mermaid: true
---
```

Then use it like any other fenced block: wrap the graph code with ```` ```mermaid ```` and ```` ``` ````.

## Images

### Caption

Add italics on the line after an image to show a caption below it:

```markdown
![img-description](/path/to/image)
_Image Caption_
```
{: .nolineno}

### Size

Set width and height on each image to avoid layout shifts while it loads:

```markdown
![Desktop View](/assets/img/sample/mockup.png){: width="700" height="400" }
```
{: .nolineno}

> For an SVG, you have to at least specify its _width_, otherwise it won't be rendered.
{: .prompt-info }

Starting from _Chirpy v5.0.0_, `height` and `width` support abbreviations (`height` → `h`, `width` → `w`). This has the same effect:

```markdown
![Desktop View](/assets/img/sample/mockup.png){: w="700" h="400" }
```
{: .nolineno}

### Position

Images center by default. To position them, use `normal`, `left`, or `right`.

> Once the position is specified, the image caption should not be added.
{: .prompt-warning }

- **Normal position**

  The image is left aligned in this example:

  ```markdown
  ![Desktop View](/assets/img/sample/mockup.png){: .normal }
  ```
  {: .nolineno}

- **Float to the left**

  ```markdown
  ![Desktop View](/assets/img/sample/mockup.png){: .left }
  ```
  {: .nolineno}

- **Float to the right**

  ```markdown
  ![Desktop View](/assets/img/sample/mockup.png){: .right }
  ```
  {: .nolineno}

### Dark/Light mode

You can swap images for dark/light mode. Provide two images and assign the `dark` or `light` class:

```markdown
![Light mode only](/path/to/light-mode.png){: .light }
![Dark mode only](/path/to/dark-mode.png){: .dark }
```

### Shadow

Program window screenshots work well with the shadow effect:

```markdown
![Desktop View](/assets/img/sample/mockup.png){: .shadow }
```
{: .nolineno}

### CDN URL

If media lives on a CDN, set `cdn` in `_config.yml`{: .filepath} to avoid repeating the URL:

```yaml
cdn: https://cdn.com
```
{: file='_config.yml' .nolineno}

Once set, the CDN URL prefixes all media paths starting with `/` (avatars, images, audio, video).

For instance, when using images:

```markdown
![The flower](/path/to/flower.png)
```
{: .nolineno}

The parsing result will automatically add the CDN prefix `https://cdn.com` before the image path:

```html
<img src="https://cdn.com/path/to/flower.png" alt="The flower" />
```
{: .nolineno }

### Media Subpath

For posts with many images, avoid repeating paths by setting `media_subpath` in the YAML block:

```yml
---
media_subpath: /img/path/
---
```

Then reference images by filename only:

```md
![The flower](flower.png)
```
{: .nolineno }

The output will be:

```html
<img src="/img/path/flower.png" alt="The flower" />
```
{: .nolineno }

### Preview Image

For a top-of-post image, use a `1200 x 630` image. If it isn't `1.91 : 1`, it will be scaled and cropped.

With that in mind, set the image attributes:

```yaml
---
image:
  path: /path/to/image
  alt: image alternative text
---
```

[`media_subpath`](#media-subpath) also applies to the preview image. If it's set, `path` only needs the filename.

For simple use, you can also just use `image` to define the path.

```yml
---
image: /path/to/image
---
```

### LQIP

For preview images:

```yaml
---
image:
  lqip: /path/to/lqip-file # or base64 URI
---
```

> You can see LQIP on the preview image of this post.

For normal images:

```markdown
![Image description](/path/to/image){: lqip="/path/to/lqip-file" }
```
{: .nolineno }

## Pinned Posts

You can pin one or more posts to the top of the home page; pinned posts sort in reverse release order. Enable with:

```yaml
---
pin: true
---
```

## Prompts

Prompt types include `tip`, `info`, `warning`, and `danger`. Add class `prompt-{type}` to a blockquote. For example:

```md
> Example line for prompt.
{: .prompt-info }
```
{: .nolineno }

## Syntax

### Inline Code

```md
`inline code part`
```
{: .nolineno }

### Filepath Highlight

```md
`/path/to/a/file.extend`{: .filepath}
```
{: .nolineno }

### Code Block

Markdown fences ```` ``` ```` create a code block:

````md
```
This is a plaintext code snippet.
```
````

#### Specifying Language

Using ```` ```{language} ```` you will get a code block with syntax highlight:

````markdown
```yaml
key: value
```
````

> The Jekyll tag `{% highlight %}` is not compatible with this theme.
{: .prompt-danger }

#### Line Number

By default, all languages except `plaintext`, `console`, and `terminal` will display line numbers. When you want to hide the line number of a code block, add the class `nolineno` to it:

````markdown
```shell
echo 'No more line numbers!'
```
{: .nolineno }
````

#### Specifying the Filename

You may have noticed that the code language will be displayed at the top of the code block. If you want to replace it with the file name, you can add the attribute `file` to achieve this:

````markdown
```shell
# content
```
{: file="path/to/file" }
````

#### Liquid Codes

If you want to display the **Liquid** snippet, surround the liquid code with `{% raw %}` and `{% endraw %}`:

````markdown
{% raw %}
```liquid
{% if product.title contains 'Pack' %}
  This product's title contains the word Pack.
{% endif %}
```
{% endraw %}
````

Or adding `render_with_liquid: false` (Requires Jekyll 4.0 or higher) to the post's YAML block.

## Videos

### Video Sharing Platform

You can embed a video with the following syntax:

```liquid
{% include embed/{Platform}.html id='{ID}' %}
```

`Platform` is the lowercase platform name and `ID` is the video ID.

The table below shows how to grab those values from supported platforms:

| Video URL                                                                                          | Platform   | ID             |
| -------------------------------------------------------------------------------------------------- | ---------- | :------------- |
| [https://www.**youtube**.com/watch?v=**H-B46URT4mg**](https://www.youtube.com/watch?v=H-B46URT4mg) | `youtube`  | `H-B46URT4mg`  |
| [https://www.**twitch**.tv/videos/**1634779211**](https://www.twitch.tv/videos/1634779211)         | `twitch`   | `1634779211`   |
| [https://www.**bilibili**.com/video/**BV1Q44y1B7Wf**](https://www.bilibili.com/video/BV1Q44y1B7Wf) | `bilibili` | `BV1Q44y1B7Wf` |

### Video File

To embed a video file directly, use:

```liquid
{% include embed/video.html src='{URL}' %}
```

Where `URL` points to a video file, e.g., `/assets/img/sample/video.mp4`.

You can also pass attributes:

- `poster='/path/to/poster.png'` - poster image for a video that is shown while video is downloading
- `title='Text'` - title for a video that appears below the video and looks same as for images
- `autoplay=true` - video automatically begins to play back as soon as it can
- `loop=true` - automatically seek back to the start upon reaching the end of the video
- `muted=true` - audio will be initially silenced
- `types` - specify the extensions of additional video formats separated by `|`. Ensure these files exist in the same directory as your primary video file.

Example with everything set:

```liquid
{%
  include embed/video.html
  src='/path/to/video/video.mp4'
  types='ogg|mov'
  poster='poster.png'
  title='Demo video'
  autoplay=true
  loop=true
  muted=true
%}
```

> Avoid hosting video files in `assets` since PWA won't cache them and it may cause issues.
> Use a CDN instead, or a folder excluded from PWA (see `pwa.deny_paths` in `_config.yml`).
{: .prompt-warning }

## Audios

### Audio File

To embed an audio file directly, use:

```liquid
{% include embed/audio.html src='{URL}' %}
```

Where `URL` points to an audio file, e.g., `/assets/img/sample/audio.mp3`.

You can also pass attributes:

- `title='Text'` - title for an audio that appears below the audio and looks same as for images
- `types` - specify the extensions of additional audio formats separated by `|`. Ensure these files exist in the same directory as your primary audio file.

Example with all options:

```liquid
{%
  include embed/audio.html
  src='/path/to/audio/audio.mp3'
  types='ogg|wav|aac'
  title='Demo audio'
%}
```

> Avoid hosting audio in `assets` since PWA won't cache them and it may cause issues.
> Use a CDN instead, or a folder excluded from PWA (see `pwa.deny_paths` in `_config.yml`).
{: .prompt-warning }

## Learn More

For more knowledge about Jekyll posts, visit the [Jekyll Docs: Posts](https://jekyllrb.com/docs/posts/).
