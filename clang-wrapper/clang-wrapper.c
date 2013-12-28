/* Clang wrapper -- provide an even more gcc-like frontend to clang crosscompilers
 * (C) 2013 Bernhard Rosenkränzer <Bernhard.Rosenkranzer@linaro.org>
 * Released into the public domain - do with the code whatever you want.
 */

#include <libgen.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#ifndef CLANG_PATH
#define CLANG_PATH "."
//#define CLANG_PATH "/usr/bin"
#endif

int main(int argc, char **argv) {
	char *clang_path = strdup(CLANG_PATH);
	char *tool = basename(argv[0]);
	char *basetool, *triplet, *command;
	if(clang_path[0] != '/') { // Relative CLANG_PATH -- let's resolve it
		char *d=realpath(dirname(argv[0]), NULL);
		char *p=(char*)malloc(strlen(d)+strlen(CLANG_PATH)+2);
		sprintf(p, "%s/%s", d, CLANG_PATH);
		clang_path = realpath(p, NULL);
		free(d);
		free(p);
	}

#ifndef CLANG_TARGET
	if(strchr(tool, '-')) {
		basetool = strrchr(tool, '-')+1;
		triplet = strdup(tool);
		*strrchr(triplet, '-') = 0;
	} else {
		FILE *cg;
		basetool = tool;
		cg = popen("/usr/share/libtool/config/config.guess", "r");
		if(cg) {
			triplet = (char*)malloc(512);
			if(!fgets(triplet, 512, cg)) {
				fprintf(stderr, "Couldn't determine target triplet\n");
				exit(1);
			}
			if(strchr(triplet, '\n'))
				*strchr(triplet, '\n') = 0;
			pclose(cg);
		} else {
			fprintf(stderr, "Couldn't determine target triplet\n");
			exit(1);
		}
	}
#else
    basetool = tool;
    triplet = strdup(CLANG_TARGET);
#endif

	command = (char*) malloc(strlen(clang_path) + 9);
	if(!strcmp(basetool, "g++") || !strcmp(basetool, "c++"))
		sprintf(command, "%s/clang++", clang_path);
	else /* Default for anything... */
		sprintf(command, "%s/clang", clang_path);

	char **new_argv = (char**) malloc(sizeof(char*)*(argc+26));
	new_argv[0] = command;
	new_argv[1] = strdup("-target");
	new_argv[2] = triplet;
	int arg = 3;
	// Target specific defaults go first so actual flags can override them
	if(!strncmp(triplet, "arm", 3) && strstr(triplet, "-android")) {
		// arm-linux-androideabi fixes the enum size to 32 bits
		new_argv[arg++] = strdup("-fno-short-enums");
		// Android uses the softfp ABI
		new_argv[arg++] = strdup("-mfloat-abi=softfp");
		// Android defaults to PIC
		new_argv[arg++] = strdup("-fPIC");
	}

	int cortex_m = 0, is_asm = 0;
	for(int i = 1; i < argc; i++) {
		// Emulate gcc's built-in __ARM_FEATURE_DSP define
		// -m{tune,cpu}=cortex-m ==> no DSP
		if(strstr(argv[i], "=cortex-m"))
			cortex_m = 1;
		// Check if we're building assembly code -- if so, we
		// have to turn any -I statement into -Wa,-I (as of 3.4,
		// clang doesn't pass -I statements to the assembler)
		const int l = strlen(argv[i]);
		if((argv[i][0] != '-') && (((l >= 4) && !strcmp(argv[i]+l-4, ".asm")) || ((l >= 2) && !strcmp(argv[i]+l-2, ".s"))))
			is_asm = 1;
	}

	if(!cortex_m)
		new_argv[arg++] = strdup("-D__ARM_FEATURE_DSP=1");
	for(int i = 1; i < argc; i++) {
		if(!strcmp(argv[i], "--version")) {
			// Let's pretend we're a modern gcc for the sake of maximum compatibility
			// with stuff that makes assumptions based on the GCC version...
			printf("%s (Linaro GCC 4.8-2013.09-1~dev) 4.8.2 20130822 (prerelease)\n", basename(argv[0]));
			printf("\nActually, a wrapper around clang trying to simulate gcc as closely as possible\n\n");
			char cmd[512];
			snprintf(cmd, 512, "%s --version", command);
			FILE *f=popen(cmd, "r");
			if(f) {
				while(!feof(f)) {
					char buf[512];
					if(fgets(buf, 512, f))
						printf("%s", buf);
				}
				pclose(f);
			}
			goto out;
		// not exactly the same, but covers many of the same cases
		} else if(!strcmp(argv[i], "-Wno-unused-but-set-variable")) {
			new_argv[arg++] = strdup("-Wno-unused-const-variable");
			continue;
		// gcc can take -Wstrict-aliasing=X, clang just supports -Wstrict-aliasing without parameters
		} else if(!strncmp(argv[i], "-Wstrict-aliasing=", 18)) {
			new_argv[arg++] = strdup("-Wstrict-aliasing");
			continue;
		// gcc options that don't have/need a replacement in clang
		} else if(!strcmp(argv[i], "-mthumb-interwork") ||
		          !strcmp(argv[i], "-mno-thumb-interwork") ||
		          !strcmp(argv[i], "-mbig-endian") ||
		          !strcmp(argv[i], "-mlittle-endian") ||
		          !strcmp(argv[i], "-fgcse-after-reload") ||
			  !strcmp(argv[i], "-frerun-cse-after-loop") ||
			  !strcmp(argv[i], "-frename-registers") ||
			  !strncmp(argv[i], "-finline-limit=", 15) ||
			  !strncmp(argv[i], "-Wframe-larger-than=", 20) ||
			  !strcmp(argv[i], "-fno-delete-null-pointer-checks") ||
			  !strcmp(argv[i], "-fno-inline-functions-called-once") ||
			  !strcmp(argv[i], "-fno-inline-small-functions") ||
			  !strcmp(argv[i], "-Wno-psabi") ||
			  !strcmp(argv[i], "-fno-align-jumps") ||
			  !strcmp(argv[i], "-fno-builtin-sin") ||
			  !strcmp(argv[i], "-fno-builtin-cos") ||
			  !strcmp(argv[i], "-fstrict-volatile-bitfields") ||
			  !strcmp(argv[i], "-fno-strict-volatile-bitfields") ||
			  !strcmp(argv[i], "-funswitch-loops") ||
			  !strcmp(argv[i], "-fno-tree-sra")
		         ) {
			continue;
		// -I for asm files
		} else if(is_asm && (!strncmp(argv[i], "-I", 2))) {
			if(strlen(argv[i]) == 2 && i<argc) {
				// If there's a space between -I and the path, let's remove
				// it so we don't have to prepend -Wa, to the next parameter...
				new_argv[arg] = (char*)malloc(strlen(argv[i])+strlen(argv[i+1])+5);
				sprintf(new_argv[arg++], "-Wa,%s%s", argv[i], argv[i+1]);
				i++;
			} else {
				new_argv[arg] = (char*)malloc(strlen(argv[i])+5);
				sprintf(new_argv[arg++], "-Wa,%s", argv[i]);
			}
			continue;
		}
		// gcc doesn't barf on strange standard mismatches like "g++ -std=gnu99" -- clang does
		// We hit this e.g. with the C++ malloc debug implementation in the otherwise C Bionic
		else if(!strcmp(argv[i], "-std=gnu99") && strstr(command, "clang++"))
			continue;
		new_argv[arg++] = argv[i];
	}
	/* Don't let warnings gcc doesn't emit break the build for the time being */
	new_argv[arg++] = strdup("-Wno-error=unknown-warning-option");
	new_argv[arg++] = strdup("-Wno-error=unused-parameter");
	new_argv[arg++] = strdup("-Wno-error=gnu-static-float-init");
	new_argv[arg++] = strdup("-Wno-error=unused-private-field");
	new_argv[arg++] = strdup("-Wno-error=mismatched-tags");
	new_argv[arg++] = strdup("-Wno-error=ignored-attributes");
	new_argv[arg++] = strdup("-Wno-error=gnu-designator");
	new_argv[arg++] = strdup("-Wno-error=gnu");
	new_argv[arg++] = strdup("-Wno-error=duplicate-decl-specifier");
	new_argv[arg++] = strdup("-Wno-error=tautological-constant-out-of-range-compare");
	new_argv[arg++] = strdup("-Wno-error=unsequenced");
	new_argv[arg++] = strdup("-Wno-error=return-type-c-linkage");
	new_argv[arg++] = strdup("-Wno-error=unused-function");
	new_argv[arg++] = strdup("-Wno-error=unused-const-variable");
	new_argv[arg++] = strdup("-Wno-error=deprecated-register");
	new_argv[arg++] = strdup("-Wno-error=compare-distinct-pointer-types");
	new_argv[arg++] = strdup("-Wno-error=c++11-extensions");
	/* Don't barf on -W options that differ between gcc and clang either */
	new_argv[arg++] = strdup("-Wno-error=unknown-warning-option");
	new_argv[arg++] = strdup("-Wno-error=unknown-pragmas");
	new_argv[arg] = NULL;

	for(int i=0; i<arg; i++)
		printf("%s ", new_argv[i]);
	printf("\n");

	execv(new_argv[0], new_argv);
out:
	free(clang_path);
	free(command);
	free(triplet);
	free(new_argv[1]);
	free(new_argv);
	return 0;
}
