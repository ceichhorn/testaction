#!/bin/bash

REPO="ceichhorn/testaction"
TAG="v0.0.4"
MERGE=$(git log --pretty=format:"{\"merge\":[{\"sha\":\"%H\",\"author\":\"%an\",\"summary\":\"%s\"}]}" | head -1)
          SUMMARY=$(echo ${MERGE} | jq -r '.merge[].summary' | sed 's/\#//g' | sed 's/ceichhorn\///g')
          SHA=$(echo ${MERGE} | jq -r '.merge[].sha')
          git_tag_response=$(
            curl -s "https://api.github.com/repos/${REPO}/git/tags" \
              -H "authorization: Bearer ${GITHUB_TOKEN}" \
              -H "Accept: application/vnd.github.v3+json" \
              -H "Content-Type: application/json"  \
              -d '{
                  "tag":"${TAG}",
                  "message":"${SUMMARY}",
                  "object":"${SHA}",
                  "type":"commit"
              }'
          )
echo "Summary: $SUMMARY"
echo "Sha:  $SHA"
echo "$git_tag_response"
          git_refs_response=$(
            curl -s "https://api.github.com/repos/${REPO}/git/refs" \
            -H "Authorization: Bearer ${GITHUB_TOKEN}" \
            -H "Accept: application/vnd.github.v3+json" \
            -H "Content-Type: application/json"  \
            -d '{
              "ref": "refs/tags/${TAG}",
              "sha": "'$(echo $git_tag_response | jq -r '.sha' )'"
            }'
          )
          git_ref_posted=$( echo "${git_refs_response}" | jq -r '.ref' )
          echo "$git_ref_posted"
          if [ "${git_ref_posted}" = "refs/tags/${TAG}" ]; then
            echo "::notice::Tagging repo"
          else
            echo ::error::Tag was not created properly. Github ref response: ${git_ref_posted} and TAG: ${TAG}
            exit 1
          fi