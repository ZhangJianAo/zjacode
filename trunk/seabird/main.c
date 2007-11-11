#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <vector>

#define ACT_BUILD 1
#define ACT_QUERY 2

typedef struct {
	unsigned char *term;
	int len;
} TermInfo;

typedef struct {
	unsigned char *term;
	std::vector<int> *docList;
} TermIndex;

typedef struct {
	TermIndex idx[65536];
} Index;

/* segment string for each char, suppose the input is GBK encoding */
int segment(unsigned char *input, int len, TermInfo **info)
{
	TermInfo buf[1024];
	int n = 0;
	int i = 0;
	size_t size = 0;

	assert(len <= strlen((char*)input));

	/* avoi duplicate term in output */
	while(i < len) {
		buf[n].term = &(input[i]);
		if (input[i] > 128) {
			buf[n].len = 2;
			i++;
		} else {
			buf[n].len = 1;
		}

		n++;
		i++;
	}

	if (0 < n) {
		size = sizeof(**info) * n;
		*info = (TermInfo *)malloc(size);
		memcpy(*info, buf, size);
	}

	return n;
}

int
indexRow(Index *idx, int docId, char *doc)
{
	int i = 0;
	unsigned short c = 0;
	TermInfo *terms = NULL;
	TermInfo *term = NULL;
	TermIndex *ti = NULL;

	int nterm = segment((unsigned char*)doc, strlen(doc), &terms);
	term = terms;

	for(i = 0; i < nterm; i++) {
		if (1 == term->len) {
			c = term->term[0];
		} else {
			c = term->term[0] << 8 | term->term[1];
		}
	
		ti = &(idx->idx[c]);

		if (NULL == ti->term) {
			ti->term = (unsigned char *)malloc(term->len + 1);
			bzero(ti->term, term->len + 1);
			ti->docList = new std::vector<int>();
			memcpy(ti->term, term->term, term->len);
		}

		ti->docList->push_back(docId);

		term++;
	}

	if (NULL != terms) {
		free(terms);
	}

	return nterm;
}

Index *
buildIndex(FILE *pf)
{
	char *sep;
	char *id, *doc;
	int len;
	char buf[256];
	Index *ret = (Index *)malloc(sizeof(*ret));
	bzero(ret, sizeof(*ret));

	while(fgets(buf, sizeof(buf), pf)) {
		len = strlen(buf);
		if (len > sizeof(buf)) {
			continue;
		}
		if ('\n' == buf[len-1]) {
			buf[len-1] = '\0';
		}
		sep = strchr(buf, '\t');
		if (NULL == sep) {
			continue;
		}
		*sep = '\0';
		id = buf;
		doc = sep + 1;

		indexRow(ret, atoi(id), doc);
	}

	return ret;
}

int
allHasValue(TermIndex **idxList, int *pos, int len)
{
	int i = 0;
	for(i = 0; i < len; i++) {
		if (pos[i] >= idxList[i]->docList->size()) {
			return 0;
		}
	}

	return 1;
}

int
findFrom(std::vector<int> *docList, int from, int find, int *ret)
{
	std::vector<int> &list = *docList;
	int i = from;
	
	while( (i < list.size()) && (list[i] < find) ) {
		i++;
	}
	
	*ret = i;

	if (i >= list.size()) {
		return 0;
	} else {
		if (list[i] == find) {
			return 1;
		} else {
			return 0;
		}
	}

	return 0;
}

int
getDocId(std::vector<int> *docList, int pos)
{
	std::vector<int> &list = *docList;
	return list[pos];
}

int
join(TermIndex **idxList, int len, std::vector<int> *ret)
{
	int pos[128] = { 0 };
	int i = 0;
	int curDoc = 0;
	int finded = 0;

	for(i = 0; i < len; i++) {
		if ((NULL == idxList[i])
		    || (NULL == idxList[i]->docList)
		    || (0 >= idxList[i]->docList->size())) {
			return 0;
		}

		pos[i] = 0;

		if (idxList[i]->docList->front() > curDoc) {
			curDoc = idxList[i]->docList->front();
		}
	}

	do {
		finded = 1;
		for(i = 0; i < len; i++) {
			if (!findFrom(idxList[i]->docList, pos[i], curDoc, &pos[i])) {
				curDoc = getDocId(idxList[i]->docList, pos[i]);
				finded = 0;
			}
		}

		if (finded) {
			ret->push_back(curDoc);
			if (idxList[0]->docList->size() > pos[0]) {
				pos[0] = pos[0] + 1;
				curDoc = getDocId(idxList[0]->docList, pos[0]);
			} 
		}
	} while(allHasValue(idxList, pos, len));

	return 0;
}

int
search(Index *idx, char *query)
{
	int i = 0;
	int nterm = 0;
	unsigned short c = 0;
	TermInfo *terms = NULL;
	TermInfo *term = NULL;
	TermIndex *ti = NULL;
	TermIndex *idxList[128];
	std::vector<int> docList;

	nterm = segment((unsigned char*)query, strlen(query), &terms);
	
	term = terms;

	for(i = 0; i < nterm; i++) {
		if (1 == term->len) {
			c = term->term[0];
		} else {
			c = term->term[0] << 8 | term->term[1];
		}
	
		ti = &(idx->idx[c]);

		idxList[i] = ti;

		term++;
	}

	join(idxList, i, &docList);

	for(i = 0; i < docList.size(); i++) {
		printf("%d\n", docList[i]);
	}

	return 0;
}

int
main(int argc, char **argv)
{
	int action = ACT_QUERY;
	int i = 1;
	FILE *input = NULL;
	char line[256];
	int len = 0;
	Index *idx = NULL;

	/* check if first arg is action */
	if ((argc > 1) && ('-' != argv[1][0])) {
		if (0 == strcmp(argv[1], "build")) {
			action = ACT_BUILD;
		}

		i++;
	}

	input = fopen("/Users/zja/zjacode/seabird/input.txt", "r");
	idx = buildIndex(input);
	fclose(input);

	printf("Hello World\n");

	search(idx, "ft");

	while(fgets(line, sizeof(line), stdin)) {
		len = strlen(line);
		if (len >= sizeof(line)) {
			continue;
		}

		if ('\n' == line[len - 1]) {
			line[len - 1] = '\0';
		}

		search(idx, line);
	}

	return 0;
}

