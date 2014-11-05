" Vim completion script  - hit 80% complete tasks
" Version:  0.77.1.2
" Language:  Java
" Maintainer:  cheng fang <fangread@yahoo.com.cn>
" Last Change:  2011-01-30
" Copyright:  Copyright (C) 2006-2007 cheng fang. All rights reserved.
" License:  Vim License  (see vim's :help license)

let s:V= vital#of('javacomplete')
let s:P= s:V.import('Process')
let s:S= s:V.import('Data.String')
unlet s:V

" constants              {{{1
" input context type
let s:CONTEXT_AFTER_DOT     = 'after dot' " 1
let s:CONTEXT_METHOD_PARAM  = 'method param' " 2
let s:CONTEXT_IMPORT        = 'import' " 3
let s:CONTEXT_IMPORT_STATIC = 'static import' " 4
let s:CONTEXT_PACKAGE_DECL  = 'package declaration' " 6
let s:CONTEXT_NEED_TYPE     = 'need type' " 7
let s:CONTEXT_OTHER         = 'other' " 0

let s:ARRAY_TYPE_MEMBERS= [
\   {'kind': 'f', 'dup': 0, 'word': 'length',     'abbr': 'length',      'menu': 'int'},
\   {'kind': 'm', 'dup': 0, 'word': 'clone(',     'abbr': 'clone()',     'menu': 'Object clone()'},
\   {'kind': 'm', 'dup': 0, 'word': 'equals(',    'abbr': 'equals()',    'menu': 'boolean equals(Object)'},
\   {'kind': 'm', 'dup': 0, 'word': 'getClass(',  'abbr': 'getClass()',  'menu': 'Class Object.getClass()'},
\   {'kind': 'm', 'dup': 0, 'word': 'hashCode(',  'abbr': 'hashCode()',  'menu': 'int hashCode()'},
\   {'kind': 'm', 'dup': 0, 'word': 'notify(',    'abbr': 'notify()',    'menu': 'void Object.notify()'},
\   {'kind': 'm', 'dup': 0, 'word': 'notifyAll(', 'abbr': 'notifyAll()', 'menu': 'void Object.notifyAll()'},
\   {'kind': 'm', 'dup': 0, 'word': 'toString(',  'abbr': 'toString()',  'menu': 'String toString()'},
\   {'kind': 'm', 'dup': 0, 'word': 'wait(',      'abbr': 'wait()',      'menu': 'void Object.wait()'},
\   {'kind': 'm', 'dup': 1, 'word': 'wait(',      'abbr': 'wait()',      'menu': 'void Object.wait(long timeout)'},
\   {'kind': 'm', 'dup': 1, 'word': 'wait(',      'abbr': 'wait()',      'menu': 'void Object.wait(long timeout, int nanos)'},
\]

let s:ARRAY_TYPE_INFO= {
\   'tag': 'CLASSDEF',
\   'name': '[',
\   'ctors': [],
\   'fields': [{'n': 'length', 'm': '1', 't': 'int'}],
\   'methods':[
\       {'n': 'clone',     'm': '1',         'r': 'Object',  'p': [],             'd': 'Object clone()'},
\       {'n': 'equals',    'm': '1',         'r': 'boolean', 'p': ['Object'],     'd': 'boolean Object.equals(Object obj)'},
\       {'n': 'getClass',  'm': '100010001', 'r': 'Class',   'p': [],             'd': 'Class Object.getClass()'},
\       {'n': 'hashCode',  'm': '100000001', 'r': 'int',     'p': [],             'd': 'int Object.hashCode()'},
\       {'n': 'notify',    'm': '100010001', 'r': 'void',    'p': [],             'd': 'void Object.notify()'},
\       {'n': 'notifyAll', 'm': '100010001', 'r': 'void',    'p': [],             'd': 'void Object.notifyAll()'},
\       {'n': 'toString',  'm': '1',         'r': 'String',  'p': [],             'd': 'String Object.toString()'},
\       {'n': 'wait',      'm': '10001',     'r': 'void',    'p': [],             'd': 'void Object.wait()'},
\       {'n': 'wait',      'm': '100010001', 'r': 'void',    'p': ['long'],       'd': 'void Object.wait(long timeout)'},
\       {'n': 'wait',      'm': '10001',     'r': 'void',    'p': ['long','int'], 'd': 'void Object.wait(long timeout, int nanos)'},
\    ],
\}

let s:PRIMITIVE_TYPE_INFO= {
\   'tag': 'CLASSDEF',
\   'name': '!',
\   'fields': [{'n': 'class','m': '1','t': 'Class'}],
\}

let s:JSP_BUILTIN_OBJECTS = {'session':  'javax.servlet.http.HttpSession',
\  'request':      'javax.servlet.http.HttpServletRequest',
\  'response':     'javax.servlet.http.HttpServletResponse',
\  'pageContext':  'javax.servlet.jsp.PageContext',
\  'application':  'javax.servlet.ServletContext',
\  'config':       'javax.servlet.ServletConfig',
\  'out':          'javax.servlet.jsp.JspWriter',
\  'page':         'javax.servlet.jsp.HttpJspPage', }


let s:PRIMITIVE_TYPES= ['boolean', 'byte', 'char', 'int', 'short', 'long', 'float', 'double']
let s:KEYWORDS_MODS=   ['public', 'private', 'protected', 'static', 'final', 'synchronized', 'volatile', 'transient', 'native', 'strictfp', 'abstract']
let s:KEYWORDS_TYPE=   ['class', 'interface', 'enum']
let s:KEYWORDS=        s:PRIMITIVE_TYPES + s:KEYWORDS_MODS + s:KEYWORDS_TYPE + ['super', 'this', 'void'] + ['assert', 'break', 'case', 'catch', 'const', 'continue', 'default', 'do', 'else', 'extends', 'finally', 'for', 'goto', 'if', 'implements', 'import', 'instanceof', 'interface', 'new', 'package', 'return', 'switch', 'throw', 'throws', 'try', 'while', 'true', 'false', 'null']

if has("win32") || has("win64") || has("win16") || has("dos32") || has("dos16")
    let s:PATH_SEP  = ';'
    let s:FILE_SEP  = '\'
else
    let s:PATH_SEP  = ':'
    let s:FILE_SEP  = '/'
endif

let s:RE_BRACKETS  = '\%(\s*\[\s*\]\)'
let s:RE_IDENTIFIER  = '[a-zA-Z_$][a-zA-Z0-9_$]*'
let s:RE_QUALID    = s:RE_IDENTIFIER. '\%(\s*\.\s*' .s:RE_IDENTIFIER. '\)*'

let s:RE_REFERENCE_TYPE  = s:RE_QUALID . s:RE_BRACKETS . '*'
let s:RE_TYPE    = s:RE_REFERENCE_TYPE

let s:RE_TYPE_ARGUMENT  = '\%(?\s\+\%(extends\|super\)\s\+\)\=' . s:RE_TYPE
let s:RE_TYPE_ARGUMENTS  = '<' . s:RE_TYPE_ARGUMENT . '\%(\s*,\s*' . s:RE_TYPE_ARGUMENT . '\)*>'
let s:RE_TYPE_WITH_ARGUMENTS_I  = s:RE_IDENTIFIER . '\s*' . s:RE_TYPE_ARGUMENTS
let s:RE_TYPE_WITH_ARGUMENTS  = s:RE_TYPE_WITH_ARGUMENTS_I . '\%(\s*' . s:RE_TYPE_WITH_ARGUMENTS_I . '\)*'

let s:RE_TYPE_MODS  = '\%(public\|protected\|private\|abstract\|static\|final\|strictfp\)'
let s:RE_TYPE_DECL_HEAD  = '\(class\|interface\|enum\)[ \t\n\r]\+'
let s:RE_TYPE_DECL  = '\<\C\(\%(' .s:RE_TYPE_MODS. '\s\+\)*\)' .s:RE_TYPE_DECL_HEAD. '\(' .s:RE_IDENTIFIER. '\)[< \t\n\r]'

let s:RE_ARRAY_TYPE  = '^\s*\(' .s:RE_QUALID . '\)\(' . s:RE_BRACKETS . '\+\)\s*$'
let s:RE_SELECT_OR_ACCESS  = '^\s*\(' . s:RE_IDENTIFIER . '\)\s*\(\[.*\]\)\=\s*$'
let s:RE_ARRAY_ACCESS  = '^\s*\(' . s:RE_IDENTIFIER . '\)\s*\(\[.*\]\)\+\s*$'
let s:RE_CASTING  = '^\s*(\(' .s:RE_QUALID. '\))\s*\(' . s:RE_IDENTIFIER . '\)\>'

let s:RE_KEYWORDS  = '\<\%(' . join(s:KEYWORDS, '\|') . '\)\>'


" local variables            {{{1
" precending - expression ends with '.'
" incomplete - incomplete word: 1. precending.method(|) 2. new classname(|) 3. precending.ab|, 4. ja|, 5. method(|
let s:context_prototype= {
\   'context_type': s:CONTEXT_OTHER,
\   'precending':      '',
\   'incomplete':   '',
\}

" script variables            {{{1
let s:cache = {}  " FQN -> member list, e.g. {'java.lang.StringBuffer': classinfo, 'java.util': packageinfo, '/dir/TopLevelClass.java': compilationUnit}
let s:files = {}  " source file path -> properties, e.g. {filekey: {'unit': compilationUnit, 'changedtick': tick, }}

let s:reflection= javacomplete#reflection#new()
let s:ctags= javacomplete#ctags#new()

let s:source= {}

function! s:source.get_complete_pos(context)
    let start = col('.') - 1

    let statement = s:GetStatement()

    if statement =~ '[.0-9A-Za-z_]\s*$'
        let valid = 1
        if statement =~ '\.\s*$'
            let valid = statement =~ '[")0-9A-Za-z_\]]\s*\.\s*$' && statement !~ '\<\H\w\+\.\s*$' && statement !~ '\<\(abstract\|assert\|break\|case\|catch\|const\|continue\|default\|do\|else\|enum\|extends\|final\|finally\|for\|goto\|if\|implements\|import\|instanceof\|interface\|native\|new\|package\|private\|protected\|public\|return\|static\|strictfp\|switch\|synchronized\|throw\|throws\|transient\|try\|volatile\|while\|true\|false\|null\)\.\s*$'
        endif
        if !valid
            return -1
        endif

        let a:context.context_type= s:CONTEXT_AFTER_DOT

        " import or package declaration
        if statement =~# '^\s*\(import\|package\)\s\+'
            let statement = substitute(statement, '\s\+\.', '.', 'g')
            let statement = substitute(statement, '\.\s\+', '.', 'g')
            if statement =~ '^\s*import\s\+'
                let a:context.context_type= (statement =~# '\<static\s\+') ? s:CONTEXT_IMPORT_STATIC : s:CONTEXT_IMPORT
                let a:context.precending=   substitute(statement, '^\s*import\s\+\(static\s\+\)\?', '', '')
            else
                let a:context.context_type= s:CONTEXT_PACKAGE_DECL
                let a:context.precending=   substitute(statement, '\s*package\s\+', '', '')
            endif

            " String literal
        elseif statement =~  '"\s*\.\s*$'
            let a:context.precending= substitute(statement, '\s*\.\s*$', '\.', '')
            return start - strlen(a:context.incomplete)

        else
            " type declaration    NOTE: not supported generic yet.
            silent! let idx_type = matchend(statement, '^\s*' . s:RE_TYPE_DECL)
            if idx_type != -1
                let a:context.precending= strpart(statement, idx_type)
                " return if not after extends or implements
                if a:context.precending !~ '^\(extends\|implements\)\s\+'
                    return -1
                endif
                let a:context.context_type = s:CONTEXT_NEED_TYPE
            endif

            let a:context.precending = s:ExtractCleanExpr(statement)
        endif

        " all cases: " java.ut|" or " java.util.|" or "ja|"
        let a:context.incomplete = strpart(a:context.precending, strridx(a:context.precending, '.')+1)
        let a:context.precending = strpart(a:context.precending, 0, strridx(a:context.precending, '.')+1)
        return start - strlen(a:context.incomplete)


        " method parameters, treat methodname or 'new' as an incomplete word
    elseif statement =~ '(\s*$'
        " TODO: Need to exclude method declaration?
        let a:context.context_type = s:CONTEXT_METHOD_PARAM
        let pos = strridx(statement, '(')
        let s:padding = strpart(statement, pos+1)
        let start = start - (len(statement) - pos)

        let statement = substitute(statement, '\s*(\s*$', '', '')

        " new ClassName?
        let str = matchstr(statement, '\<new\s\+' . s:RE_QUALID . '$')
        if str != ''
            let str = substitute(str, '^new\s\+', '', '')
            if !s:IsKeyword(str)
                let a:context.incomplete = '+'
                let a:context.precending = str
                return start - len(a:context.precending)
            endif

            " normal method invocations
        else
            let pos = match(statement, '\s*' . s:RE_IDENTIFIER . '$')
            " case: "method(|)", "this(|)", "super(|)"
            if pos == 0
                let statement = substitute(statement, '^\s*', '', '')
                " treat "this" or "super" as a type name.
                if statement == 'this' || statement == 'super' 
                    let a:context.precending = statement
                    let a:context.incomplete = '+'
                    return start - len(a:context.precending)

                elseif !s:IsKeyword(statement)
                    let a:context.incomplete = statement
                    return start - strlen(a:context.incomplete)
                endif

                " case: "expr.method(|)"
            elseif statement[pos-1] == '.' && !s:IsKeyword(strpart(statement, pos))
                let a:context.precending = s:ExtractCleanExpr(strpart(statement, 0, pos))
                let a:context.incomplete = strpart(statement, pos)
                return start - strlen(a:context.incomplete)
            endif
        endif
    endif

    return -1
endfunction

function! s:source.gather_candidates(context)
    " TODO: remove this
    let a:context.precending= s:S.trim(a:context.precending)
    let a:context.incomplete= s:S.trim(a:context.incomplete)

    if empty(a:context.precending) && empty(a:context.incomplete)
        return []
    endif

    let result= []
    if !empty(a:context.precending)
        if a:context.context_type ==# s:CONTEXT_AFTER_DOT
            let result= s:CompleteAfterDot(a:context.precending)
        elseif a:context.context_type ==# s:CONTEXT_IMPORT ||
        \   a:context.context_type ==# s:CONTEXT_IMPORT_STATIC ||
        \   a:context.context_type ==# s:CONTEXT_PACKAGE_DECL ||
        \   a:context.context_type ==# s:CONTEXT_NEED_TYPE
            let result= s:GetMembers(a:context, s:S.substitute_last(a:context.precending, '\.', ''))
        elseif a:context.context_type ==# s:CONTEXT_METHOD_PARAM
            if a:context.incomplete ==# '+'
                let result= s:GetConstructorList(a:context.precending)
            else
                let result= s:CompleteAfterDot(a:context.precending)
            endif
        endif

        " only incomplete word
    elseif !empty(a:context.incomplete)
        " only need methods
        if a:context.context_type ==# s:CONTEXT_METHOD_PARAM
            let methods= s:SearchForName(a:context.incomplete, 0, 1)[1]
            call extend(result, eval('[' . s:DoGetMethodList(methods) . ']'))
        else
            let result= s:CompleteAfterWord(a:context)
        endif

        " then no filter needed
        let a:context.incomplete= ''
    endif

    " filter according to b:incomplete
    if !empty(a:context.incomplete) && a:context.incomplete !=# '+'
        let result= filter(result, "type(v:val) == type('') ? v:val =~ '^" . a:context.incomplete . "' : v:val['word'] =~ '^" . a:context.incomplete . "'")
    endif

    if exists('s:padding') && !empty(s:padding)
        for item in result
            if type(item) == type("")
                let item.= s:padding
            else
                let item.word.= s:padding
            endif
        endfor
        unlet s:padding
    endif

    return result
endfunction

" This function is used for the 'omnifunc' option.    {{{1
function! javacomplete#Complete(findstart, base)
    " reset enviroment
    let b:javacomplete_context= deepcopy(get(b:, 'javacomplete_context', s:context_prototype))

    try
        if a:findstart
            return s:source.get_complete_pos(b:javacomplete_context)
        else
            return s:source.gather_candidates(b:javacomplete_context)
        endif
    catch /\C^javacomplete:/
        echoerr v:exception
    endtry
endfunction

" Precondition:  incomplete must be a word without '.'.
" return all the matched, variables, fields, methods, types, packages
function! s:CompleteAfterWord(context)
    let incomplete= a:context.incomplete
    let context_type= a:context.context_type

    " packages in jar files
    if !exists('s:all_packages_in_jars_loaded')
        " {'package name': {'tag': 'PACKAGE', 'classes': ['simple class name', ...]}}
        for pkgname in s:reflection.packages()
            let s:cache[pkgname]= s:reflection.package_info(pkgname)
        endfor
        let s:all_packages_in_jars_loaded = 1
    endif

    let packages= []
    for pkgname in filter(s:reflection.packages(), "v:val =~# '^" . incomplete . "'")
        let packages+= [{'kind': 'P', 'word': pkgname}]
    endfor

    let types= []
    if context_type !=# s:CONTEXT_PACKAGE_DECL && context_type !=# s:CONTEXT_IMPORT && context_type !=# s:CONTEXT_IMPORT_STATIC
        for class in filter(s:reflection.classes(), "v:val =~# '^" . incomplete . "'")
            let types+= [{'kind': 'C', 'word': class}]
        endfor
    endif

    let packages+= s:DoGetPackageInfoInDirs(incomplete, context_type == s:CONTEXT_PACKAGE_DECL, 1)

    " add accessible types which name beginning with the incomplete in source files
    " TODO: remove the inaccessible
    if context_type !=# s:CONTEXT_PACKAGE_DECL
        " single type import
        for fqn in s:GetImports('imports_fqn')
            let name = fqn[strridx(fqn, ".")+1:]
            if name =~ '^' . incomplete
                let types+= [{'kind': 'C', 'word': name}]
            endif
        endfor

        " current file
        " TODO: improve
        let lnum_old= line('.')
        let col_old= col('.')
        call cursor(1, 1)
        while 1
            let lnum= search('\<\C\(class\|interface\|enum\)\_s\+' . incomplete . '[a-zA-Z0-9_$]*[\_s', 'W')
            if lnum == 0
                break
            elseif s:InCommentOrLiteral(line('.'), col('.'))
                continue
            else
                normal w
                let types+= [{'kind': 'C', 'word': matchstr(getline(line('.'))[col('.')-1:], s:RE_IDENTIFIER)}]
            endif
        endwhile
        call cursor(lnum_old, col_old)

        " other files
        for dirpath in s:GetSourceDirs(expand('%:p'))
            let tags= s:ctags.find_types({'path': dirpath, 'recurse': 'no'})
            for tag in tags
                if tag.class =~# '^' . incomplete && (tag.modifiers.is_public || fnamemodify(tag.file, ':p:h') == expand('%:p:h'))
                    let types+= [{'kind': 'C', 'word': tag.class}]
                endif
            endfor
        endfor
    endif

    let result= []

    " add variables and members in source files
    if context_type ==# s:CONTEXT_AFTER_DOT
        let matches= s:SearchForName(incomplete, 0, 0)
        let result+= sort(eval('[' . s:DoGetFieldList(matches[2]) . ']'))
        let result+= sort(eval('[' . s:DoGetMethodList(matches[1]) . ']'))
    endif
    let result+= sort(packages)
    let result+= sort(types)

    return result
endfunction

" Precondition:  expr must end with '.'
" return members of the value of expression
function! s:CompleteAfterDot(expr)
    let items = s:ParseExpr(a:expr)    " TODO: return a dict containing more than items
    if empty(items)
        return []
    endif

    " 0. String literal
    if items[-1] =~ '"$'
        return s:GetMemberList("java.lang.String")
    endif


    let ti = {}
    let ii = 1    " item index
    let itemkind = 0

    "
    " optimized process
    "
    " search the longest expr consisting of ident
    let i = 1
    let k = i
    while i < len(items) && items[i] =~ '^\s*' . s:RE_IDENTIFIER . '\s*$'
        let ident = substitute(items[i], '\s', '', 'g')
        if ident == 'class' || ident == 'this' || ident == 'super'
            let k = i
            " return when found other keywords
        elseif s:IsKeyword(ident)
            return []
        endif
        let items[i] = substitute(items[i], '\s', '', 'g')
        let i += 1
    endwhile

    if i > 1
        " cases: "this.|", "super.|", "ClassName.this.|", "ClassName.super.|", "TypeName.class.|"
        if items[k] ==# 'class' || items[k] ==# 'this' || items[k] ==# 'super'
            let ti = s:DoGetClassInfo(items[k] == 'class' ? 'java.lang.Class' : join(items[:k-1], '.'))
            if !empty(ti)
                let itemkind = items[k] ==# 'this' ? 1 : items[k] ==# 'super' ? 2 : 0
                let ii = k+1
            else
                return []
            endif

            " case: "java.io.File.|"
        else
            let fqn = join(items[:i-1], '.')
            let srcpath = join(s:GetSourceDirs(expand('%:p'), s:GetPackageName()), ',')
            call s:DoGetTypeInfoForFQN([fqn], srcpath)
            if get(get(s:cache, fqn, {}), 'tag', '') == 'CLASSDEF'
                let ti = s:cache[fqn]
                let itemkind = 11
                let ii = i
            endif
        endif
    endif


    "
    " first item
    "
    if empty(ti)
        " cases:
        " 1) "int.|", "void.|"  - primitive type or pseudo-type, return `class`
        " 2) "this.|", "super.|"  - special reference
        " 3) "var.|"    - variable or field
        " 4) "String.|"     - type imported or defined locally
        " 5) "java.|"       - package
        if items[0] =~ '^\s*' . s:RE_IDENTIFIER . '\s*$'
            let ident = substitute(items[0], '\s', '', 'g')

            if s:IsKeyword(ident)
                " 1)
                if ident ==# 'void' || s:IsBuiltinType(ident)
                    let ti = s:PRIMITIVE_TYPE_INFO
                    let itemkind = 11

                    " 2)
                elseif ident ==# 'this' || ident ==# 'super'
                    let itemkind = ident ==# 'this' ? 1 : ident ==# 'super' ? 2 : 0
                    let ti = s:DoGetClassInfo(ident)
                endif

            else
                " 3)
                let typename = s:GetDeclaredClassName(ident)
                if (typename != '')
                    if typename[0] == '[' || typename[-1:] == ']'
                        let ti = s:ARRAY_TYPE_INFO
                    elseif typename != 'void' && !s:IsBuiltinType(typename)
                        let ti = s:DoGetClassInfo(typename)
                    endif

                else
                    " 4)
                    let ti = s:DoGetClassInfo(ident)
                    let itemkind = 11

                    if get(ti, 'tag', '') != 'CLASSDEF'
                        let ti = {}
                    endif

                    " 5)
                    if empty(ti)
                        unlet ti
                        let ti = s:GetMembers(b:javacomplete_context, ident)  " s:DoGetPackegInfo(ident)
                        let itemkind = 20
                    endif
                endif
            endif

            " method invocation:  "method().|"  - "this.method().|"
        elseif items[0] =~ '^\s*' . s:RE_IDENTIFIER . '\s*('
            let ti = s:MethodInvocation(items[0], ti, itemkind)

            " array type, return `class`: "int[] [].|", "java.lang.String[].|", "NestedClass[].|"
        elseif items[0] =~# s:RE_ARRAY_TYPE
            let qid = substitute(items[0], s:RE_ARRAY_TYPE, '\1', '')
            if s:IsBuiltinType(qid) || (!s:HasKeyword(qid) && !empty(s:DoGetClassInfo(qid)))
                let ti = s:PRIMITIVE_TYPE_INFO
                let itemkind = 11
            endif

            " class instance creation expr:  "new String().|", "new NonLoadableClass().|"
            " array creation expr:  "new int[i=1] [val()].|", "new java.lang.String[].|"
        elseif items[0] =~ '^\s*new\s\+'
            let subs = split(substitute(items[0], '^\s*new\s\+\(' .s:RE_QUALID. '\)\s*\([([]\)', '\1;\2', ''), ';')
            if subs[1][0] == '['
                let ti = s:ARRAY_TYPE_INFO
            elseif subs[1][0] == '('
                let ti = s:DoGetClassInfo(subs[0])
                " exclude interfaces and abstract class.  TODO: exclude the inaccessible
                if get(ti, 'flags', '')[-10:-10] || get(ti, 'flags', '')[-11:-11]
                    echo 'cannot instantiate the type ' . subs[0]
                    let ti = {}
                    return []
                endif
            endif

            " casting conversion:  "(Object)o.|"
        elseif items[0] =~ s:RE_CASTING
            let subs = split(substitute(items[0], s:RE_CASTING, '\1;\2', ''), ';')
            let ti = s:DoGetClassInfo(subs[0])

            " array access:  "var[i][j].|"    Note: "var[i][]" is incorrect
        elseif items[0] =~# s:RE_ARRAY_ACCESS
            let subs = split(substitute(items[0], s:RE_ARRAY_ACCESS, '\1;\2', ''), ';')
            if get(subs, 1, '') !~ s:RE_BRACKETS
                let typename = s:GetDeclaredClassName(subs[0])
                if (typename != '')
                    let ti = s:ArrayAccess(typename, items[0])
                endif
            endif
        endif
    endif


    "
    " next items
    "
    while !empty(ti) && ii < len(items)
        " method invocation:  "PrimaryExpr.method(parameters)[].|"
        if items[ii] =~ '^\s*' . s:RE_IDENTIFIER . '\s*('
            let ti = s:MethodInvocation(items[ii], ti, itemkind)
            let itemkind = 0
            let ii += 1
            continue


            " expression of selection, field access, array access
        elseif items[ii] =~ s:RE_SELECT_OR_ACCESS
            let subs = split(substitute(items[ii], s:RE_SELECT_OR_ACCESS, '\1;\2', ''), ';')
            let ident = subs[0]
            let brackets = get(subs, 1, '')

            " package members
            if itemkind/10 == 2 && empty(brackets) && !s:IsKeyword(ident)
                let qn = join(items[:ii], '.')
                if type(ti) == type([])
                    let idx = s:Index(ti, ident, 'word')
                    if idx >= 0
                        if ti[idx].kind == 'P'
                            unlet ti
                            let ti = s:GetMembers(b:javacomplete_context, qn)
                            let ii += 1
                            continue
                        elseif ti[idx].kind == 'C'
                            unlet ti
                            let ti = s:DoGetClassInfo(qn)
                            let itemkind = 11
                            let ii += 1
                            continue
                        endif
                    endif
                endif


                " type members
            elseif itemkind/10 == 1 && empty(brackets)
                if ident ==# 'class' || ident ==# 'this' || ident ==# 'super'
                    let ti = s:DoGetClassInfo(ident == 'class' ? 'java.lang.Class' : join(items[:ii-1], '.'))
                    let itemkind = ident ==# 'this' ? 1 : ident ==# 'super' ? 2 : 0
                    let ii += 1
                    continue

                elseif !s:IsKeyword(ident) && type(ti) == type({}) && get(ti, 'tag', '') == 'CLASSDEF'
                    " accessible static field
                    "let idx = s:Index(get(ti, 'fields', []), ident, 'n')
                    "if idx >= 0 && s:IsStatic(ti.fields[idx].m)
                    "  let ti = s:ArrayAccess(ti.fields[idx].t, items[ii])
                    let members = s:SearchMember(ti, ident, 1, itemkind, 1, 0)
                    if !empty(members[2])
                        let ti = s:ArrayAccess(members[2][0].t, items[ii])
                        let itemkind = 0
                        let ii += 1
                        continue
                    endif

                    " accessible nested type
                    "if !empty(filter(copy(get(ti, 'classes', [])), 'strpart(v:val, strridx(v:val, ".")) ==# "' . ident . '"'))
                    if !empty(members[0])
                        let ti = s:DoGetClassInfo(join(items[:ii], '.'))
                        let ii += 1
                        continue
                    endif
                endif


                " instance members
            elseif itemkind/10 == 0 && !s:IsKeyword(ident)
                if type(ti) == type({}) && get(ti, 'tag', '') == 'CLASSDEF'
                    "let idx = s:Index(get(ti, 'fields', []), ident, 'n')
                    "if idx >= 0
                    "  let ti = s:ArrayAccess(ti.fields[idx].t, items[ii])
                    let members = s:SearchMember(ti, ident, 1, itemkind, 1, 0)
                    let itemkind = 0
                    if !empty(members[2])
                        let ti = s:ArrayAccess(members[2][0].t, items[ii])
                        let ii += 1
                        continue
                    endif
                endif
            endif
        endif

        return []
    endwhile


    " type info or package info --> members
    if !empty(ti)
        if type(ti) == type({})
            if get(ti, 'tag', '') == 'CLASSDEF'
                if get(ti, 'name', '') == '!'
                    return [{'kind': 'f', 'word': 'class', 'menu': 'Class'}]
                elseif get(ti, 'name', '') == '['
                    return s:ARRAY_TYPE_MEMBERS
                elseif itemkind < 20
                    return s:DoGetMemberList(ti, itemkind)
                endif
            elseif get(ti, 'tag', '') == 'PACKAGE'
                " TODO: ti -> members, in addition to packages in dirs
                return s:GetMembers(b:javacomplete_context, substitute(join(items, '.'), '\s', '', 'g') )
            endif
        elseif type(ti) == type([])
            return ti
        endif
    endif

    return []
endfunction


fu! s:MethodInvocation(expr, ti, itemkind)
    let subs = split(substitute(a:expr, '\s*\(' . s:RE_IDENTIFIER . '\)\s*\((.*\)', '\1;\2', ''), ';')

    " all methods matched
    if empty(a:ti)
        let methods = s:SearchForName(subs[0], 0, 1)[1]
    elseif type(a:ti) == type({}) && get(a:ti, 'tag', '') == 'CLASSDEF'
        let methods = s:SearchMember(a:ti, subs[0], 1, a:itemkind, 1, 0, a:itemkind == 2)[1]
        "    let methods = s:filter(get(a:ti, 'methods', []), 'item.n == "' . subs[0] . '"')
        "    if a:itemkind == 1 || a:itemkind == 2
        "      let methods += s:filter(get(a:ti, 'declared_methods', []), 'item.n == "' . subs[0] . '"')
        "    endif
    else
        let methods = []
    endif

    let method = s:DetermineMethod(methods, subs[1])
    if !empty(method)
        return s:ArrayAccess(method.r, a:expr)
    endif
    return {}
endfu

fu! s:ArrayAccess(arraytype, expr)
    if a:expr =~ s:RE_BRACKETS  | return {} | endif
    let typename = a:arraytype

    let dims = 0
    if typename[0] == '[' || typename[-1:] == ']' || a:expr[-1:] == ']'
        let dims = s:CountDims(a:expr) - s:CountDims(typename)
        if dims == 0
            let typename = matchstr(typename, s:RE_IDENTIFIER)
        elseif dims < 0
            return s:ARRAY_TYPE_INFO
        else
            "echoerr 'dims exceeds'
        endif
    endif
    if dims == 0
        if typename != 'void' && !s:IsBuiltinType(typename)
            return s:DoGetClassInfo(typename)
        endif
    endif
    return {}
endfu


" Quick information            {{{1
function! MyBalloonExpr()
    if (searchdecl(v:beval_text, 1, 0) == 0)
        return s:GetVariableDeclaration()
    endif
    return ''
    "  return 'Cursor is at line ' . v:beval_lnum .
    "  \', column ' . v:beval_col .
    "  \ ' of file ' .  bufname(v:beval_bufnr) .
    "  \ ' on word "' . v:beval_text . '"'
endfunction
"set bexpr=MyBalloonExpr()
"set ballooneval

" parameters information          {{{1
fu! javacomplete#CompleteParamsInfo(findstart, base)
    if a:findstart
        return col('.') - 1
    endif


    let mi = s:GetMethodInvocationExpr(s:GetStatement())
    if empty(mi.method)
        return []
    endif

    " TODO: how to determine overloaded functions
    "let mi.params = s:EvalParams(mi.params)
    if empty(mi.expr)
        let methods = s:SearchForName(mi.method, 0, 1)[1]
        let result = eval('[' . s:DoGetMethodList(methods) . ']')
    elseif mi.method == '+'
        let result = s:GetConstructorList(mi.expr)
    else
        let result = s:CompleteAfterDot(mi.expr)
    endif

    if !empty(result)
        if !empty(mi.method) && mi.method != '+'
            let result = filter(result, "type(v:val) == type('') ? v:val ==# '" . mi.method . "' : v:val['word'] ==# '" . mi.method . "('")
        endif
        return result
    endif
endfu

" scanning and parsing              {{{1

" Search back from the cursor position till meeting '{' or ';'.
" '{' means statement start, ';' means end of a previous statement.
" Return: statement before cursor
" Note: It's the base for parsing. And It's OK for most cases.
function! s:GetStatement()
    let input= getline('.')

    if input =~ '\C^\s*\%(import\|package\)\s\+'
        return strpart(input, match(input, '\C\%(import\|package\)'), col('.') - 1)
    endif

    let save_pos= getpos('.')
    try
        let [to_lnum, to_col]= [line('.'), col('.')]

        while 1
            let found_pos= searchpos('\C\%([{};]\|<%\|<%!\)', 'Web')

            if found_pos == [0, 0]
                let [from_lnum, from_col]= [1, 1]
                break
            elseif !s:InCommentOrLiteral(found_pos[0], found_pos[1])
                let [from_lnum, from_col]= [found_pos[0], found_pos[1] + 1]
                break
            endif
        endwhile

        return s:MergeLines(from_lnum, from_col, to_lnum, to_col)
    finally
        call setpos('.', save_pos)
    endtry
endfunction

function! s:MergeLines(from_lnum, from_col, to_lnum, to_col)
    let from= [a:from_lnum, a:from_col]
    let to= [a:to_lnum, a:to_col]

    if (from[0] > to[0]) || (from[0] == to[0] && from[1] > to[1])
        throw printf('javacomplete: illegal range specified, cannot merge [%d, %d] to [%d, %d].', from[0], from[1], to[0], to[1])
    endif

    let buf= []
    if from[0] < to[0]
        let buf+= [s:Prune(strpart(getline(from[0]), from[1] - 1))]
        let from[0]+= 1

        while from[0] < to[0]
            let buf+= [s:Prune(getline(from[0]))]
            let from[0]+= 1
        endwhile

        let from[1]= 1
    endif

    let lastline= strpart(getline(to[0]), from[1] - 1, to[1] - from[1])
    let buf+= [s:Prune(lastline, from[1])]

    let str = s:RemoveBlockComments(join(buf, ''))
    " generic in JAVA 5+
    while match(str, s:RE_TYPE_ARGUMENTS) != -1
        let str= substitute(str, '\C\(' . s:RE_TYPE_ARGUMENTS . '\)', '\=repeat(" ", len(submatch(1)))', 'g')
    endwhile

    let str= substitute(str, '\s\+', ' ', 'g')

    return s:S.trim(str) . matchstr(lastline, '\s*$')
endfunction

" Extract a clean expr, removing some non-necessary characters. 
fu! s:ExtractCleanExpr(expr)
    let cmd = substitute(a:expr, '[ \t\r\n]\+\([.()[\]]\)', '\1', 'g')
    let cmd = substitute(cmd, '\([.()[\]]\)[ \t\r\n]\+', '\1', 'g')

    let pos = strlen(cmd)-1 
    while pos >= 0 && cmd[pos] =~ '[a-zA-Z0-9_.)\]]'
        if cmd[pos] == ')'
            let pos = s:SearchPairBackward(cmd, pos, '(', ')')
        elseif cmd[pos] == ']'
            let pos = s:SearchPairBackward(cmd, pos, '[', ']')
        endif
        let pos -= 1
    endwhile

    " try looking back for "new"
    let idx = match(strpart(cmd, 0, pos+1), '\<new[ \t\r\n]*$')

    return strpart(cmd, idx != -1 ? idx : pos+1)
endfu

fu! s:ParseExpr(expr)
    let items = []
    let s = 0
    " recognize ClassInstanceCreationExpr as a whole
    let e = matchend(a:expr, '^\s*new\s\+' . s:RE_QUALID . '\s*[([]')-1
    if e < 0
        let e = match(a:expr, '[.([]')
    endif
    let isparen = 0
    while e >= 0
        if a:expr[e] == '.'
            let subexpr = strpart(a:expr, s, e-s)
            call extend(items, isparen ? s:ProcessParentheses(subexpr) : [subexpr])
            let isparen = 0
            let s = e + 1
        elseif a:expr[e] == '('
            let e = s:GetMatchedIndexEx(a:expr, e, '(', ')')
            let isparen = 1
            if e < 0
                break
            else
                let e = matchend(a:expr, '^\s*[.[]', e+1)-1
                continue
            endif
        elseif a:expr[e] == '['
            let e = s:GetMatchedIndexEx(a:expr, e, '[', ']')
            if e < 0
                break
            else
                let e = matchend(a:expr, '^\s*[.[]', e+1)-1
                continue
            endif
        endif
        let e = match(a:expr, '[.([]', s)
    endwhile
    let tail = strpart(a:expr, s)
    if tail !~ '^\s*$'
        call extend(items, isparen ? s:ProcessParentheses(tail) : [tail])
    endif

    return items
endfu

" Given optional argument, call s:ParseExpr() to parser the nonparentheses expr
fu! s:ProcessParentheses(expr, ...)
    let s = matchend(a:expr, '^\s*(')
    if s != -1
        let e = s:GetMatchedIndexEx(a:expr, s-1, '(', ')')
        if e >= 0
            let tail = strpart(a:expr, e+1)
            if tail =~ '^\s*[\=$'
                return s:ProcessParentheses(strpart(a:expr, s, e-s), 1)
            elseif tail =~ '^\s*\w'
                return [strpart(a:expr, 0, e+1) . 'obj.']
            endif
        endif

        " multi-dot-expr except for new expr
    elseif a:0 > 0 && stridx(a:expr, '.') != match(a:expr, '\.\s*$') && a:expr !~ '^\s*new\s\+'
        return s:ParseExpr(a:expr)
    endif
    return [a:expr]
endfu

" return {'expr': , 'method': , 'params': }
fu! s:GetMethodInvocationExpr(expr)
    let idx = strlen(a:expr)-1 
    while idx >= 0
        if a:expr[idx] == '('
            break
        elseif a:expr[idx] == ')'
            let idx = s:SearchPairBackward(a:expr, idx, '(', ')')
        elseif a:expr[idx] == ']'
            let idx = s:SearchPairBackward(a:expr, idx, '[', ']')
        endif
        let idx -= 1
    endwhile

    let mi = {'expr': strpart(a:expr, 0, idx+1), 'method': '', 'params': strpart(a:expr, idx+1)}
    let idx = match(mi.expr, '\<new\s\+' . s:RE_QUALID . '\s*(\s*$')
    if idx >= 0
        let mi.method = '+'
        let mi.expr = substitute(matchstr(strpart(mi.expr, idx+4), s:RE_QUALID), '\s', '', 'g')
    else
        let idx = match(mi.expr, '\<' . s:RE_IDENTIFIER . '\s*(\s*$')
        if idx >= 0
            let subs = s:SplitAt(mi.expr, idx-1)
            let mi.method = substitute(subs[1], '\s*(\s*$', '', '')
            let mi.expr = s:ExtractCleanExpr(subs[0])
        endif
    endif
    return mi
endfu

" imports              {{{1
function! s:GenerateImports()
    let imports = []

    let lnum_old = line('.')
    let col_old = col('.')
    call cursor(1, 1)

    if &ft == 'jsp'
        while 1
            let lnum = search('\<import\s*=[''"]', 'W')
            if (lnum == 0)
                break
            endif

            let str = getline(lnum)
            if str =~ '<%\s*@\s*page\>' || str =~ '<jsp:\s*directive.page\>'
                let str = substitute(str, '.*import=[''"]\([a-zA-Z0-9_$.*, \t]\+\)[''"].*', '\1', '')
                for item in split(str, ',')
                    call add(imports, substitute(item, '\s', '', 'g'))
                endfor
            endif
        endwhile
    else
        while 1
            let lnum = search('\<import\>', 'W')
            if (lnum == 0)
                break
            elseif !s:InComment(line("."), col(".")-1)
                normal w
                " TODO: search semicolon or import keyword, excluding comment
                let stat = matchstr(getline(lnum)[col('.')-1:], '\(static\s\+\)\?\(' .s:RE_QUALID. '\%(\s*\.\s*\*\)\?\)\s*;')
                if !empty(stat)
                    call add(imports, stat[:-2])
                endif
            endif
        endwhile
    endif

    call cursor(lnum_old, col_old)
    return imports
endfunction

fu! s:GetImports(kind, ...)
    let filekey = a:0 > 0 && !empty(a:1) ? a:1 : s:GetCurrentFileKey()
    let props = get(s:files, filekey, {})
    if !has_key(props, a:kind)
        let props['imports']  = filekey == s:GetCurrentFileKey() ? s:GenerateImports() : props.unit.imports
        let props['imports_static']  = []
        let props['imports_fqn']  = []
        let props['imports_star']  = ['java.lang.']
        if &ft == 'jsp' || filekey =~ '\.jsp$'
            let props.imports_star += ['javax.servlet.', 'javax.servlet.http.', 'javax.servlet.jsp.']
        endif

        for import in props.imports
            let subs = split(substitute(import, '^\s*\(static\s\+\)\?\(' .s:RE_QUALID. '\%(\s*\.\s*\*\)\?\)\s*$', '\1;\2', ''), ';', 1)
            let qid = substitute(subs[1] , '\s', '', 'g')
            if !empty(subs[0])
                call add(props.imports_static, qid)
            elseif qid[-1:] == '*'
                call add(props.imports_star, qid[:-2])
            else
                call add(props.imports_fqn, qid)
            endif
        endfor
        let s:files[filekey] = props
    endif
    return get(props, a:kind, [])
endfu

" search for name in 
" return the fqn matched
fu! s:SearchSingleTypeImport(name, fqns)
    let matches = s:filter(a:fqns, 'item =~# ''\<' . a:name . '$''')
    if len(matches) == 1
        return matches[0]
    elseif !empty(matches)
        echoerr 'Name "' . a:name . '" conflicts between ' . join(matches, ' and ')
        return matches[0]
    endif
    return ''
endfu

" search for name in static imports, return list of members with the same name
" return [types, methods, fields]
fu! s:SearchStaticImports(name, fullmatch)
    let result = [[], [], []]
    let candidates = []    " list of the canonical name
    for item in s:GetImports('imports_static')
        if item[-1:] == '*'    " static import on demand
            call add(candidates, item[:-3])
        elseif item[strridx(item, '.')+1:] ==# a:name
        \ || (!a:fullmatch && item[strridx(item, '.')+1:] =~ '^' . a:name)
            call add(candidates, item[:strridx(item, '.')])
        endif
    endfor
    if empty(candidates)
        return result
    endif


    " read type info which are not in cache
    let commalist = ''
    for typename in candidates
        if !has_key(s:cache, typename)
            let class= s:reflection.class_info(typename)
            if !empty(class)
                let s:cache[class.name]= class
            endif
        endif
    endfor

    " search in all candidates
    for typename in candidates
        let ti = get(s:cache, typename, 0)
        if type(ti) == type({}) && get(ti, 'tag', '') == 'CLASSDEF'
            let members = s:SearchMember(ti, a:name, a:fullmatch, 12, 1, 0)
            let result[1] += members[1]
            let result[2] += members[2]
            "let pattern = 'item.n ' . (a:fullmatch ? '==# ''' : '=~# ''^') . a:name . ''' && s:IsStatic(item.m)'
            "let result[1] += s:filter(get(ti, 'methods', []), pattern)
            "let result[2]  += s:filter(get(ti, 'fields', []),  pattern)
        else
            " TODO: mark the wrong import declaration.
        endif
    endfor
    return result
endfu


" search decl              {{{1
" Return: The declaration of identifier under the cursor
" Note: The type of a variable must be imported or a fqn.
function! s:GetVariableDeclaration()
    let lnum_old = line('.')
    let col_old = col('.')

    silent call search('[^a-zA-Z0-9$_.,?<>[\] \t\r\n]', 'bW')  " call search('[{};(,]', 'b')
    normal w
    let lnum = line('.')
    let col = col('.')
    if (lnum == lnum_old && col == col_old)
        return ''
    endif

    "  silent call search('[;){]')
    "  let lnum_end = line('.')
    "  let col_end  = col('.')
    "  let declaration = ''
    "  while (lnum <= lnum_end)
    "    let declaration = declaration . getline(lnum)
    "    let lnum = lnum + 1
    "  endwhile
    "  let declaration = strpart(declaration, col-1)
    "  let declaration = substitute(declaration, '\.[ \t]\+', '.', 'g')

    silent call cursor(lnum_old, col_old)
    return s:MergeLines(lnum, col, lnum_old, col_old)
endfunction

function! s:FoundClassDeclaration(type)
    let lnum_old = line('.')
    let col_old = col('.')
    call cursor(1, 1)
    while 1
        let lnum = search('\<\C\(class\|interface\|enum\)[ \t\n\r]\+' . a:type . '[< \t\n\r]', 'W')
        if lnum == 0 || !s:InCommentOrLiteral(line('.'), col('.'))
            break
        endif
    endwhile

    " search mainly for the cases: " class /* block comment */ Ident"
    "         " class // comment \n Ident "
    if lnum == 0
        let found = 0
        while !found
            let lnum = search('\<\C\(class\|interface\|enum\)[ \t\n\r]\+', 'W')
            if lnum == 0
                break
            elseif s:InCommentOrLiteral(line('.'), col('.'))
                continue
            else
                normal w
                " skip empty line
                while getline(line('.'))[col('.')-1] == ''
                    normal w
                endwhile
                let lnum = line('.')
                let col = col('.')
                while 1
                    if match(getline(lnum)[col-1:], '^[ \t\n\r]*' . a:type . '[< \t\n\r]') >= 0
                        let found = 1
                        " meets comment
                    elseif match(getline(lnum)[col-1:], '^[ \t\n\r]*\(//\|/\*\)') >= 0
                        if getline(lnum)[col-1:col] == '//'
                            normal $eb
                        else
                            let lnum = search('\*\/', 'W')
                            if lnum == 0
                                break
                            endif
                            normal web
                        endif
                        let lnum = line('.')
                        let col = col('.')
                        continue
                    endif
                    break
                endwhile
            endif
        endwhile
    endif

    silent call cursor(lnum_old, col_old)
    return lnum
endfu

fu! s:FoundClassLocally(type)
    " current path
    if globpath(expand('%:p:h'), a:type . '.java') != ''
        return 1
    endif

    " 
    let srcpath = javacomplete#GetSourcePath(1)
    let file = globpath(srcpath, substitute(fqn, '\.', '/', 'g') . '.java')
    if file != ''
        return 1
    endif

    return 0
endfu

" regexp samples:
" echo search('\(\(public\|protected|private\)[ \t\n\r]\+\)\?\(\(static\)[ \t\n\r]\+\)\?\(\<class\>\|\<interface\>\)[ \t\n\r]\+HelloWorld[^a-zA-Z0-9_$]', 'W')
" echo substitute(getline('.'), '.*\(\(public\|protected\|private\)[ \t\n\r]\+\)\?\(\(static\)[ \t\n\r]\+\)\?\(\<class\>\|\<interface\>\)\s\+\([a-zA-Z0-9_]\+\)\s\+\(\(implements\|extends\)\s\+\([^{]\+\)\)\?\s*{.*', '["\1", "\2", "\3", "\4", "\5", "\6", "\8", "\9"]', '')
" code sample: 
function! s:GetClassDeclarationOf(type)
    call cursor(1, 1)
    let decl = []

    let lnum = search('\(\<class\>\|\<interface\>\)[ \t\n\r]\+' . a:type . '[^a-zA-Z0-9_$]', 'W')
    if (lnum != 0)
        " TODO: search back for optional 'public | private' and 'static'
        " join lines till to '{'
        let lnum_end = search('{')
        if (lnum_end != 0)
            let str = ''
            while (lnum <= lnum_end)
                let str = str . getline(lnum)
                let lnum = lnum + 1
            endwhile

            exe "let decl = " . substitute(str, '.*\(\<class\>\|\<interface\>\)\s\+\([a-zA-Z0-9_]\+\)\s\+\(\(implements\|extends\)\s\+\([^{]\+\)\)\?\s*{.*', '["\1", "\2", "\4", "\5"]', '')
        endif
    endif

    return decl
endfunction

" return list
"    0  class | interface
"    1  name
"   [2  implements | extends ]
"   [3  parent list ]
function! s:GetThisClassDeclaration()
    let lnum_old = line('.')
    let col_old = col('.')

    while (1)
        call search('\(\<class\C\>\|\<interface\C\>\|\<enum\C\>\)[ \t\r\n]\+', 'bW')
        if !s:InComment(line("."), col(".")-1)
            if getline('.')[col('.')-2] !~ '\S'
                break
            endif
        end
    endwhile

    " join lines till to '{'
    let str = ''
    let lnum = line('.')
    call search('{')
    let lnum_end = line('.')
    while (lnum <= lnum_end)
        let str = str . getline(lnum)
        let lnum = lnum + 1
    endwhile


    let declaration = substitute(str, '.*\(\<class\>\|\<interface\>\)\s\+\([a-zA-Z0-9_]\+\)\(\s\+\(implements\|extends\)\s\+\([^{]\+\)\)\?\s*{.*', '["\1", "\2", "\4", "\5"]', '')
    call cursor(lnum_old, col_old)
    if declaration !~ '^['
        echoerr 'Some error occurs when recognizing this class:' . declaration
        return ['', '']
    endif
    exe "let list = " . declaration
    return list
endfunction

" searches for name of a var or a field and determines the meaning  {{{1

" The standard search order of a variable or field is as follows:
" 1. Local variables declared in the code block, for loop, or catch clause
"    from current scope up to the most outer block, a method or an initialization block
" 2. Parameters if the code is in a method or ctor
" 3. Fields of the type
" 4. Accessible inherited fields.
" 5. If the type is a nested type,
"    local variables of the enclosing block or fields of the enclosing class.
"    Note that if the type is a static nested type, only static members of an enclosing block or class are searched
"    Reapply this rule to the upper block and class enclosing the enclosing type recursively
" 6. Accessible static fields imported.
"    It is allowed that several fields with the same name.

" The standard search order of a method is as follows:
" 1. Methods of the type
" 2. Accessible inherited methods.
" 3. Methods of the enclosing class if the type is a nested type.
" 4. Accessible static methods imported.
"    It is allowed that several methods with the same name and signature.

" first    return at once if found one.
" fullmatch  1 - equal, 0 - match beginning
" return [types, methods, fields, vars]
fu! s:SearchForName(name, first, fullmatch)
    let result = [[], [], [], []]
    if s:IsKeyword(a:name)
        return result
    endif

    " use java_parser.vim
    if javacomplete#GetSearchdeclMethod() == 4
        " declared in current file
        let unit = javacomplete#parse()
        let targetPos = java_parser#MakePos(line('.')-1, col('.')-1)
        let trees = s:SearchNameInAST(unit, a:name, targetPos, a:fullmatch)
        for tree in trees
            if tree.tag == 'VARDEF'
                call add(result[2], tree)
            elseif tree.tag == 'METHODDEF'
                call add(result[1], tree)
            elseif tree.tag == 'CLASSDEF'
                call add(result[0], tree.name)
            endif
        endfor

        if a:first && result != [[], [], [], []]  | return result | endif

        " Accessible inherited members
        let type = get(s:SearchTypeAt(unit, targetPos), -1, {})
        if !empty(type)
            let members = s:SearchMember(type, a:name, a:fullmatch, 2, 1, 0, 1)
            let result[0] += members[0]
            let result[1] += members[1]
            let result[2] += members[2]
            "      "let ti = s:AddInheritedClassInfo({}, type)
            "      if !empty(ti)
            "  let comparator = a:fullmatch ? "=~# '^" : "==# '"
            "  let result[0] += s:filter(get(ti, 'classes', []), 'item   ' . comparator . a:name . "'")
            "  let result[1] += s:filter(get(ti, 'methods', []), 'item.n ' . comparator . a:name . "'")
            "  let result[2] += s:filter(get(ti, 'fields', []),  'item.n ' . comparator . a:name . "'")
            "  if a:0 > 0
            "    let result[1] += s:filter(get(ti, 'declared_methods', []), 'item.n ' . comparator . a:name . "'")
            "    let result[2] += s:filter(get(ti, 'declared_fields', []),  'item.n ' . comparator . a:name . "'")
            "  endif
            "  if a:first && result != [[], [], [], []]  | return result | endif
            "      endif
        endif

        " static import
        let si = s:SearchStaticImports(a:name, a:fullmatch)
        let result[1] += si[1]
        let result[2] += si[2]
    endif
    return result
endfu

" TODO: how to determine overloaded functions
fu! s:DetermineMethod(methods, parameters)
    return get(a:methods, 0, {})
endfu

" Parser.GetType() in insenvim
function! s:GetDeclaredClassName(var)
    let var = s:S.trim(a:var)
    if var =~# '^\(this\|super\)$'
        return var
    endif


    " Special handling for builtin objects in JSP
    if &ft == 'jsp'
        if get(s:JSP_BUILTIN_OBJECTS, a:var, '') != ''
            return s:JSP_BUILTIN_OBJECTS[a:var]
        endif
    endif

    " use java_parser.vim
    if javacomplete#GetSearchdeclMethod() == 4
        let variable = get(s:SearchForName(var, 1, 1)[2], -1, {})
        return get(variable, 'tag', '') == 'VARDEF' ? java_parser#type2Str(variable.vartype) : get(variable, 't', '')
    endif


    let ic = &ignorecase
    setlocal noignorecase

    let searched = javacomplete#GetSearchdeclMethod() == 2 ? s:Searchdecl(var, 1, 0) : searchdecl(var, 1, 0)
    if (searched == 0)
        " code sample:
        " String tmp; java.
        "   lang.  String str, value;
        " for (int i = 0, j = 0; i < 10; i++) {
        "   j = 0;
        " }
        let declaration = s:GetVariableDeclaration()
        " Assume it a class member, and remove modifiers
        let class = substitute(declaration, '^\(public\s\+\|protected\s\+\|private\s\+\|abstract\s\+\|static\s\+\|final\s\+\|native\s\+\)*', '', '')
        let class = substitute(class, '\s*\([a-zA-Z0-9_.]\+\)\(\[\]\)\?\s\+.*', '\1\2', '')
        let class = substitute(class, '\([a-zA-Z0-9_.]\)<.*', '\1', '')
        let &ignorecase = ic
        if class != '' && class !=# a:var && class !=# 'import' && class !=# 'class'
            return class
        endif
    endif

    let &ignorecase = ic
    return ''
endfunction

" using java_parser.vim          {{{1
" javacomplete#parse()          {{{2
fu! javacomplete#parse(...)
    let filename = a:0 == 0 ? '%' : a:1

    let changed = 0
    if filename == '%'
        let filename = s:GetCurrentFileKey()
        let props = get(s:files, filename, {})
        if get(props, 'changedtick', -1) != b:changedtick
            let changed = 1
            let props.changedtick = b:changedtick
            let lines = getline('^', '$')
        endif
    else
        let props = get(s:files, filename, {})
        if get(props, 'modifiedtime', 0) != getftime(filename)
            let changed = 1
            let props.modifiedtime = getftime(filename)
            let lines = readfile(filename)
        endif
    endif

    if changed
        call java_parser#InitParser(lines)
        call java_parser#SetLogLevel(5)
        let props.unit = java_parser#compilationUnit()

        let package = has_key(props.unit, 'package') ? props.unit.package . '.' : ''
        call s:UpdateFQN(props.unit, package)
    endif
    let s:files[filename] = props
    return props.unit
endfu

" update fqn for toplevel types or nested types. 
" not for local type or anonymous type
fu! s:UpdateFQN(tree, qn)
    if a:tree.tag == 'TOPLEVEL'
        for def in a:tree.types
            call s:UpdateFQN(def, a:qn)
        endfor
    elseif a:tree.tag == 'CLASSDEF'
        let a:tree.fqn = a:qn . a:tree.name
        for def in a:tree.defs
            if def.tag == 'CLASSDEF'
                call s:UpdateFQN(def, a:tree.fqn . '.')
            endif
        endfor
    endif
endfu

" TreeVisitor            {{{2
fu! s:visitTree(tree, param) dict
    if type(a:tree) == type({})
        exe get(self, get(a:tree, 'tag', ''), '')
    elseif type(a:tree) == type([])
        for tree in a:tree
            call self.visit(tree, a:param)
        endfor
    endif
endfu

let s:TreeVisitor = {'visit': function('s:visitTree'),
\ 'TOPLEVEL'  : 'call self.visit(a:tree.types, a:param)',
\ 'BLOCK'  : 'let stats = a:tree.stats | if stats == [] | call java_parser#GotoPosition(a:tree.pos) | let stats = java_parser#block().stats | endif | call self.visit(stats, a:param)',
\ 'DOLOOP'  : 'call self.visit(a:tree.body, a:param) | call self.visit(a:tree.cond, a:param)',
\ 'WHILELOOP'  : 'call self.visit(a:tree.cond, a:param) | call self.visit(a:tree.body, a:param)',
\ 'FORLOOP'  : 'call self.visit(a:tree.init, a:param) | call self.visit(a:tree.cond, a:param) | call self.visit(a:tree.step, a:param) | call self.visit(a:tree.body, a:param)',
\ 'FOREACHLOOP'  : 'call self.visit(a:tree.var, a:param)  | call self.visit(a:tree.expr, a:param) | call self.visit(a:tree.body, a:param)',
\ 'LABELLED'  : 'call self.visit(a:tree.body, a:param)',
\ 'SWITCH'  : 'call self.visit(a:tree.selector, a:param) | call self.visit(a:tree.cases, a:param)',
\ 'CASE'  : 'call self.visit(a:tree.pat,  a:param) | call self.visit(a:tree.stats, a:param)',
\ 'SYNCHRONIZED': 'call self.visit(a:tree.lock, a:param) | call self.visit(a:tree.body, a:param)',
\ 'TRY'    : 'call self.visit(a:tree.body, a:param) | call self.visit(a:tree.catchers, a:param) | call self.visit(a:tree.finalizer, a:param) ',
\ 'CATCH'  : 'call self.visit(a:tree.param,a:param) | call self.visit(a:tree.body, a:param)',
\ 'CONDEXPR'  : 'call self.visit(a:tree.cond, a:param) | call self.visit(a:tree.truepart, a:param) | call self.visit(a:tree.falsepart, a:param)',
\ 'IF'    : 'call self.visit(a:tree.cond, a:param) | call self.visit(a:tree.thenpart, a:param) | if has_key(a:tree, "elsepart") | call self.visit(a:tree.elsepart, a:param) | endif',
\ 'EXEC'  : 'call self.visit(a:tree.expr, a:param)',
\ 'APPLY'  : 'call self.visit(a:tree.meth, a:param) | call self.visit(a:tree.args, a:param)',
\ 'NEWCLASS'  : 'call self.visit(a:tree.def, a:param)'
\}

let s:TV_CMP_POS = 'a:tree.pos <= a:param.pos && a:param.pos <= get(a:tree, "endpos", -1)'
let s:TV_CMP_POS_BODY = 'has_key(a:tree, "body") && a:tree.body.pos <= a:param.pos && a:param.pos <= get(a:tree.body, "endpos", -1)'

" Return a stack of enclosing types (including local or anonymous classes).
" Given the optional argument, return all (toplevel or static member) types besides enclosing types.
fu! s:SearchTypeAt(tree, targetPos, ...)
    let s:TreeVisitor.CLASSDEF  = 'if a:param.allNonLocal || ' . s:TV_CMP_POS . ' | call add(a:param.result, a:tree) | call self.visit(a:tree.defs, a:param) | endif'
    let s:TreeVisitor.METHODDEF  = 'if ' . s:TV_CMP_POS_BODY . ' | call self.visit(a:tree.body, a:param) | endif'
    let s:TreeVisitor.VARDEF  = 'if has_key(a:tree, "init") && !a:param.allNonLocal && ' . s:TV_CMP_POS . ' | call self.visit(a:tree.init, a:param) | endif'

    let result = []
    call s:TreeVisitor.visit(a:tree, {'result': result, 'pos': a:targetPos, 'allNonLocal': a:0 == 0 ? 0 : 1})
    return result
endfu

" a:1    match beginning
" return  a stack of matching name
fu! s:SearchNameInAST(tree, name, targetPos, fullmatch)
    let comparator = a:fullmatch ? '==#' : '=~# "^" .'
    let cmd = 'if a:tree.name ' .comparator. ' a:param.name | call add(a:param.result, a:tree) | endif'
    let s:TreeVisitor.CLASSDEF  = 'if ' . s:TV_CMP_POS . ' | ' . cmd . ' | call self.visit(a:tree.defs, a:param) | endif'
    let s:TreeVisitor.METHODDEF  = cmd . ' | if ' . s:TV_CMP_POS_BODY . ' | call self.visit(a:tree.params, a:param) | call self.visit(a:tree.body, a:param) | endif'
    let s:TreeVisitor.VARDEF  = cmd . ' | if has_key(a:tree, "init") && ' . s:TV_CMP_POS . ' | call self.visit(a:tree.init, a:param) | endif'

    let result = []
    call s:TreeVisitor.visit(a:tree, {'result': result, 'pos': a:targetPos, 'name': a:name})
    return result
endfu


" javacomplete#Searchdecl        {{{2
" TODO:
fu! javacomplete#Searchdecl()
    let var  = expand('<cword>')

    let line = line('.')-1
    let col  = col('.')-1


    if var =~# '^\(this\|super\)$'
        if &ft == 'jsp'
            return ''
        endif

        let matchs = s:SearchTypeAt(javacomplete#parse(), java_parser#MakePos(line, col))

        let stat = s:GetStatement()
        for t in matchs
            if stat =~ t.name
                let coor = java_parser#DecodePos(t.pos)
                return var . '(' . (coor.line+1) . ',' . (coor.col) . ') ' . getline(coor.line+1)
            endif
        endfor
        if len(matchs) > 0
            let coor = java_parser#DecodePos(matchs[len(matchs)-1].pos)
            return var . '(' . (coor.line+1) . ',' . (coor.col) . ') ' . getline(coor.line+1)
        endif
        return ''
    endif

    " Type.this.
    " new Type()
    " new Type(param1, param2)
    " this.field
    " super.field

    " It may be an imported class.
    let imports = []
    for fqn in s:GetImports('imports_fqn')
        if fqn =~# '\<' . var . '\>$'
            call add(imports, fqn)
        endif
    endfor
    if len(imports) > 1
        echoerr 'Imports conflicts between ' . join(imports, ' and ')
    endif


    " Search in this buffer
    let matchs = s:SearchNameInAST(javacomplete#parse(), var, java_parser#MakePos(line, col), 1)


    let hint = var . ' '
    if !empty(matchs)
        let tree = matchs[len(matchs)-1]
        let coor = java_parser#DecodePos(tree.pos)
        let hint .=  '(' . (coor.line+1) . ',' . (coor.col) . ') '
        let hint .= getline(coor.line+1)    "string(tree)
    else
        for fqn in imports
            let ci = s:DoGetClassInfo(fqn)
            if !empty(ci)
                let hint .= ' ' . fqn
            endif
            " TODO: get javadoc
        endfor

    endif
    return hint
endfu


" java              {{{1

fu! s:IsBuiltinType(name)
    return index(s:PRIMITIVE_TYPES, a:name) >= 0
endfu

fu! s:IsKeyword(name)
    return index(s:KEYWORDS, a:name) >= 0
endfu

fu! s:HasKeyword(name)
    return a:name =~# s:RE_KEYWORDS
endfu

fu! s:TailOfQN(qn)
    return a:qn[strridx(a:qn, '.')+1:]
endfu

" options                {{{1
" Methods to search declaration            {{{2
"  1 - by builtin searchdecl()
"  2 - by special Searchdecl()
"  4 - by java_parser
fu! javacomplete#GetSearchdeclMethod()
    if &ft == 'jsp'
        return 1
    endif
    return exists('s:searchdecl') ? s:searchdecl : 4
endfu

fu! javacomplete#SetSearchdeclMethod(method)
    let s:searchdecl = a:method
endfu

" JDK1.1                {{{2
function! javacomplete#UseJDK11()
    let s:reflection.use_jdk11()
endfunction

" java compiler                {{{2
fu! javacomplete#GetCompiler()
    return exists('s:compiler') && s:compiler !~  '^\s*$' ? s:compiler : 'javac'
endfu

fu! javacomplete#SetCompiler(compiler)
    let s:compiler = a:compiler
endfu

" jvm launcher                {{{2
function! javacomplete#GetJVMLauncher()
    return s:reflection.jvm()
endfunction

function! javacomplete#SetJVMLauncher(interpreter)
    call s:reflection.jvm(a:interpreter)
    let s:cache = {}
endfunction

" sourcepath                {{{2
fu! javacomplete#AddSourcePath(s)
    if !isdirectory(a:s)
        echoerr 'invalid source path: ' . a:s
        return
    endif
    let path = fnamemodify(a:s, ':p:h')
    if !exists('s:sourcepath')
        let s:sourcepath = [path]
    elseif index(s:sourcepath, path) == -1
        call add(s:sourcepath, path)
    endif
endfu

fu! javacomplete#DelSourcePath(s)
    if !exists('s:sourcepath') || !isdirectory(a:s)| return   | endif
    let idx = index(s:sourcepath, a:s)
    if idx != -1
        call remove(s:sourcepath, idx)
    endif
endfu

fu! javacomplete#SetSourcePath(s)
    let paths = type(a:s) == type([]) ? a:s : split(a:s, javacomplete#GetClassPathSep())
    let s:sourcepath = []
    for path in paths
        if isdirectory(path)
            call add(s:sourcepath, fnamemodify(path, ':p:h'))
        endif
    endfor
endfu

" return the sourcepath. Given argument, add current path or default package root path
" NOTE: Avoid path duplicate, otherwise globpath() will return duplicate result.
fu! javacomplete#GetSourcePath(...)
    return join(s:GetSourceDirs(a:0 > 0 && a:1 ? expand('%:p') : ''), s:PATH_SEP)
endfu

fu! s:GetSourceDirs(filepath, ...)
    let dirs = exists('s:sourcepath') ? s:sourcepath : []

    if !empty(a:filepath)
        let filepath = fnamemodify(a:filepath, ':p:h')

        " get source path according to file path and package name
        let packageName = a:0 > 0 ? a:1 : s:GetPackageName()
        if packageName != ''
            let path = fnamemodify(substitute(filepath, packageName, '', 'g'), ':p:h')
            if index(dirs, path) < 0
                let path = javacomplete#util#convert_to_java_path(path)

                call add(dirs, path)
            endif
        endif

        " Consider current path as a sourcepath
        if index(dirs, filepath) < 0
            call add(dirs, filepath)
        endif
    endif
    return dirs
endfu

" classpath                {{{2
function! javacomplete#AddClassPath(s)
    call s:reflection.add_classpath(a:s)
    let s:cache = {}
endfunction

function! javacomplete#DelClassPath(s)
    call s:reflection.remove_classpath(a:s)
endfunction

function! javacomplete#SetClassPath(s)
    call s:reflection.set_classpath(a:s)
    let s:cache = {}
endfunction

fu! javacomplete#GetClassPathSep()
    return s:PATH_SEP
endfu

function! javacomplete#GetClassPath()
    return s:reflection.get_classpath()
endfunction

" s:GetClassPath()              {{{2
" return only classpath which are directories
fu! s:GetClassDirs()
    let dirs = []
    for path in split(s:reflection.get_classpath(), s:PATH_SEP)
        if isdirectory(path)
            call add(dirs, fnamemodify(path, ':p:h'))
        endif
    endfor
    return dirs
endfu

" s:GetPackageName()              {{{2
fu! s:GetPackageName()
    let lnum_old = line('.')
    let col_old = col('.')

    call cursor(1, 1)
    let lnum = search('^\s*package[ \t\r\n]\+\([a-zA-Z][a-zA-Z0-9.]*\);', 'w')
    let packageName = substitute(getline(lnum), '^\s*package\s\+\([a-zA-Z][a-zA-Z0-9.]*\);', '\1', '')

    call cursor(lnum_old, col_old)
    return packageName
endfu

fu! s:IsStatic(modifier)
    return a:modifier[strlen(a:modifier)-4]
endfu

" utilities              {{{1
" Convert a file name into the unique form.
" Similar with fnamemodify(). NOTE that ':gs' should not be used.
fu! s:fnamecanonize(fname, mods)
    return fnamemodify(a:fname, a:mods . ':gs?[\\/]\+?/?')
endfu

" Similar with filter(), but returns a new list instead of operating in-place.
" `item` has the value of the current item.
fu! s:filter(expr, string)
    if type(a:expr) == type([])
        let result = []
        for item in a:expr
            if eval(a:string)
                call add(result, item)
            endif
        endfor
        return result
    else
        let result = {}
        for item in items(a:expr)
            if eval(a:string)
                let result[item[0]] = item[1]
            endif
        endfor
        return result
    endif
endfu

fu! s:Index(list, expr, key)
    let i = 0
    while i < len(a:list)
        if get(a:list[i], a:key, '') == a:expr
            return i
        endif
        let i += 1
    endwhile
    return -1
endfu

fu! s:Match(list, expr, key)
    let i = 0
    while i < len(a:list)
        if get(a:list[i], a:key, '') =~ a:expr
            return i
        endif
        let i += 1
    endwhile
    return -1
endfu

fu! s:KeepCursor(cmd)
    let lnum_old = line('.')
    let col_old = col('.')
    exe a:cmd
    call cursor(lnum_old, col_old)
endfu

fu! s:InCommentOrLiteral(line, col)
    if has("syntax") && &ft != 'jsp'
        return synIDattr(synID(a:line, a:col, 1), "name") =~? '\(Comment\|String\|Character\)'
    endif
endfu

function! s:InComment(line, col)
    if has("syntax") && &ft != 'jsp'
        return synIDattr(synID(a:line, a:col, 1), "name") =~? 'comment'
    endif
    "  if getline(a:line) =~ '\s*\*'
    "    return 1
    "  endif
    "  let idx = strridx(getline(a:line), '//')
    "  if idx >= 0 && idx < a:col
    "    return 1
    "  endif
    "  return 0
endfunction

" set string literal empty, remove comments, trim begining or ending spaces
" test case: '   sb. /* block comment*/ append( "stringliteral" ) // comment '
function! s:Prune(s, ...)
    " TODO:
    let end_of_space= a:0 > 0

    if a:s =~# '^\s*$'
        return ''
    endif

    let str= a:s
    " clean up string literal
    let str= substitute(str, '"\%(\\"\|[^"]\)*"', '""', 'g')
    let str= substitute(str, '//.*', '', 'g')
    let str= s:RemoveBlockComments(str)

    return end_of_space ? str . ' ' : str
endfunction

" Given argument, replace block comments with spaces of same number
fu! s:RemoveBlockComments(str, ...)
    let result = a:str
    let ib = match(result, '\/\*')
    let ie = match(result, '\*\/')
    while ib != -1 && ie != -1 && ib < ie
        let result = strpart(result, 0, ib) . (a:0 == 0 ? ' ' : repeat(' ', ie-ib+2)) . result[ie+2: ]
        let ib = match(result, '\/\*')
        let ie = match(result, '\*\/')
    endwhile
    return result
endfu

fu! s:SplitAt(str, index)
    return [strpart(a:str, 0, a:index+1), strpart(a:str, a:index+1)]
endfu

" TODO: search pair used in string, like 
"   'create(ao.fox("("), new String).foo().'
function! s:GetMatchedIndexEx(str, idx, one, another)
    let pos = a:idx
    while 0 <= pos && pos < len(a:str)
        let pos = match(a:str, '['. a:one . escape(a:another, ']') .']', pos+1)
        if pos != -1
            if a:str[pos] == a:one
                let pos = s:GetMatchedIndexEx(a:str, pos, a:one, a:another)
            elseif a:str[pos] == a:another
                break
            endif
        endif
    endwhile
    return 0 <= pos && pos < len(a:str) ? pos : -3
endfunction

function! s:SearchPairBackward(str, idx, one, another)
    let idx = a:idx
    let n = 0
    while idx >= 0
        let idx -= 1
        if a:str[idx] == a:one
            if n == 0
                break
            endif
            let n -= 1
        elseif a:str[idx] == a:another  " nested 
            let n += 1
        endif
    endwhile
    return idx
endfunction

fu! s:CountDims(str)
    if match(a:str, '[[\]]') == -1
        return 0
    endif

    " int[] -> [I, String[] -> 
    let dims = len(matchstr(a:str, '^[\+'))
    if dims == 0
        let idx = len(a:str)-1
        while idx >= 0 && a:str[idx] == ']'
            let dims += 1
            let idx = s:SearchPairBackward(a:str, idx, '[', ']')-1
        endwhile
    endif
    return dims
endfu

fu! s:GotoUpperBracket()
    let searched = 0
    while (!searched)
        call search('[{}]', 'bW')
        if getline('.')[col('.')-1] == '}'
            normal %
        else
            let searched = 1
        endif
    endwhile
endfu

" Improve recognition of variable declaration using my version of searchdecl() for accuracy reason.
" TODO:
fu! s:Searchdecl(name, ...)
    let global = a:0 > 0 ? a:1 : 0
    let thisblock = a:0 > 1 ? a:2 : 1

    call search('\<' . a:name . '\>', 'bW')
    let lnum_old = line('.')
    let col_old = col('.')

    call s:GotoUpperBracket()
    let lnum_bracket = line('.')
    let col_bracket = col('.')
    call search('\<' . a:name . '\>', 'W', lnum_old)
    if line('.') != lnum_old || col('.') != col_old
        return 0
    endif

    " search globally
    if global
        call cursor(lnum_bracket, col_bracket)
        " search backward
        while (1)
            if search('\([{}]\|\<' . a:name . '\>\)', 'bW') == 0
                break
            endif
            if s:InComment(line('.'), col('.')) "|| s:InStringLiteral()
                continue
            endif
            let cword = expand('<cword>')
            if cword == a:name
                return 0
            endif
            if getline('.')[col('.')-1] == '}'
                normal %
            endif
        endwhile

        call cursor(lnum_old, col_old)
        " search forward
        call search('[{};]', 'W')
        while (1)
            if search('\([{}]\|\<' . a:name . '\>\)', 'W') == 0
                break
            endif
            if s:InComment(line('.'), col('.')) "|| s:InStringLiteral()
                continue
            endif
            let cword = expand('<cword>')
            if cword == a:name
                return 0
            endif
            if getline('.')[col('.')-1] == '{'
                normal %
            endif
        endwhile
    endif
    return 1
endfu
"nmap <F8> :call <SID>Searchdecl(expand('<cword>'))<CR>

fu! javacomplete#Exe(cmd)
    exe a:cmd
endfu

" cache utilities              {{{1

" key of s:files for current buffer. It may be the full path of current file or the bufnr of unnamed buffer, and is updated when BufEnter, BufLeave.
fu! s:GetCurrentFileKey()
    return has("autocmd") ? s:curfilekey : empty(expand('%')) ? bufnr('%') : expand('%:p')
endfu

fu! s:SetCurrentFileKey()
    let s:curfilekey = empty(expand('%')) ? bufnr('%') : expand('%:p')
endfu

call s:SetCurrentFileKey()
if has("autocmd")
    autocmd BufEnter *.java call s:SetCurrentFileKey()
    autocmd FileType java call s:SetCurrentFileKey()
endif

" functions to get information            {{{1
" utilities                {{{2
fu! s:MemberCompare(m1, m2)
    return a:m1['n'] == a:m2['n'] ? 0 : a:m1['n'] > a:m2['n'] ? 1 : -1
endfu

fu! s:Sort(ci)
    let ci = a:ci
    if has_key(ci, 'fields')
        call sort(ci['fields'], 's:MemberCompare')
    endif
    if has_key(ci, 'methods')
        call sort(ci['methods'], 's:MemberCompare')
    endif
    return ci
endfu

" Function to run Reflection            {{{2
" class information              {{{2


" The standard search order of a FQN is as follows:
" 1. a file-name toplevel type or static member type accessed by the file-name type declared in source files
" 2. other types declared in source files
" 3. an accessible loadable type.
" parameters:
"   fqns  - list of fqn
"   srcpaths  - a comma-separated list of directory names.
"   a:1    - search all.
" return  a dict of fqn -> type info
" precondition: 
" NOTE: call expand() to convert path to standard form
function! javacomplete#do_get_type_info_for_fqn(fqns, srcpath, ...)
    return call('s:DoGetTypeInfoForFQN', [a:fqns, a:srcpath] + a:000)
endfunction
function! javacomplete#get_cache()
    return s:cache
endfunction
fu! s:DoGetTypeInfoForFQN(fqns, srcpath, ...)
    if empty(a:fqns) || empty(a:srcpath)
        return
    endif
    let fqns= copy(a:fqns)
    let srcpaths= split(a:srcpath, ',')
    let search_all= get(a:000, 0, 1)

    " 1
    let files = {}  " fqn -> java file path
    for fqn in fqns
        let res= javacomplete#util#typename2filename(fqn, srcpaths)
        if res.found
            let files[fqn]= res.filename
        endif
    endfor
    " remove already resolved fqn
    for fqn in keys(files)
        call remove(fqns, index(fqns, fqn))
    endfor

    " 2
    let dirs = {}    " dir.idents  -> names of nested type
    " dir.qfitems  -> items of quick fix
    " dir.fqn  -> fqn
    for fqn in fqns
        let res= javacomplete#util#typename2dirname(fqn, srcpaths)
        if res.found
            let dirs[fqn]= {
            \ 'dirname': res.dirname,
            \ 'idents': res.idents,
            \}
        endif
    endfor
    " remove already resolved fqn
    for fqn in keys(dirs)
        call remove(fqns, index(fqns, fqn))
    endfor

    if !empty(dirs)
        let items = {}  " dir -> items of quick fix

        let cwd = fnamemodify(expand('%:p:h'), ':p:h:gs?[\\/]\+?/?')
        for dirpath in keys(dirs)
            let tags= s:ctags.find_types(dirpath)
            for tag in tags
                let dirpath = fnamemodify(bufname(item.bufnr), ':p:h:gs?[\\/]\+?/?')
                let idents = dirs[dirpath].idents
                if index(idents, tag.class) >= 0 && (tag.modifiers.is_public || dirpath == cwd)  " FIXME?
                    let item.subs = subs
                    let dirs[dirpath].qfitems = get(dirs[dirpath], 'qfitems', []) + [item]
                endif
            endfor
        endfor

        for dirpath in keys(dirs)
            " a. names of nested type must be existed in the same file
            "  PackageName.NonFileNameTypeName.NestedType.NestedNestedType
            let qfitems = get(dirs[dirpath], 'qfitems', [])
            let nr = 0
            for ident in dirs[dirpath].idents
                for item in qfitems
                    if item.subs[2] == ident
                        let nr += 1
                    endif
                endfor
            endfor
            if nr == len(dirs[dirpath].idents)
                " b. TODO: Check whether one enclosed another is correct
                let files[fqn] = expand(bufname(qfitems[0].bufnr))
            endif
        endfor
    endif

    for fqn in keys(files)
        let filename= files[fqn]
        let file_info= get(s:files, filename, {})

        if !has_key(s:cache, fqn) || get(file_info, 'modifiedtime', 0) != getftime(filename)
            let type_info= s:GetClassInfoFromSource(fqn[strridx(fqn, '.') + 1 : ], filename)
            if !empty(type_info)
                let s:cache[fqn]= s:Sort(type_info)
            endif
        endif

        if !search_all
            return
        endif
    endfor

    " 3
    for fqn in fqns
        let info= s:reflection.class_info(fqn)
        if !empty(info)
            let s:cache[info.name]= info
        endif
    endfor
endfu

" a:1  filepath
" a:2  package name
fu! s:DoGetClassInfo(class, ...)
    " array type:  TypeName[] or '[I' or '[[Ljava.lang.String;'
    if a:class =~# '^\s*\[\|\]\s*$'
        return s:ARRAY_TYPE_INFO
    endif

    " either this or super is not qualified
    if a:class ==# 'this' || a:class ==# 'super'
        if &ft == 'jsp'
            let ci = s:DoGetReflectionClassInfo('javax.servlet.jsp.HttpJspPage')
            if a:class == 'this'
                " TODO: search methods defined in <%! [declarations] %>
                "  search methods defined in other jsp files included
                "  avoid including self directly or indirectly
            endif
            return ci
        endif

        " this can be a local class or anonymous class as well as static type
        let t = get(s:SearchTypeAt(javacomplete#parse(), java_parser#MakePos(line('.')-1, col('.')-1)), -1, {})
        if !empty(t)
            " What will be returned for super?
            " - the protected or public inherited fields and methods. No ctors.
            " - the (public static) fields of interfaces.
            " - the methods of the Object class.
            " What will be returned for this?
            " - besides the above, all fields and methods of current class. No ctors.
            return s:Sort(s:Tree2ClassInfo(t))
            "return s:Sort(s:AddInheritedClassInfo(a:class == 'this' ? s:Tree2ClassInfo(t) : {}, t, 1))
        endif

        return {}
    endif

    if a:class !~ '^\s*' . s:RE_QUALID . '\s*$' || s:HasKeyword(a:class)
        return {}
    endif

    let typename  = s:S.trim(a:class)
    let filekey  = a:0 > 0 ? a:1 : s:GetCurrentFileKey()
    let packagename = a:0 > 1 ? a:2 : s:GetPackageName()
    let srcpath  = join(s:GetSourceDirs(a:0 > 0 && a:1 != bufnr('%') ? a:1 : expand('%:p'), packagename), ',')

    let names = split(typename, '\.')
    " remove the package name if in the same packge
    if len(names) > 1
        if packagename ==# join(names[ : -2], '.')
            let names = names[-1 : ]
        endif
    endif

    " a FQN
    if len(names) > 1
        call s:DoGetTypeInfoForFQN([typename], srcpath)
        let ci = get(s:cache, typename, {})
        if get(ci, 'tag', '') == 'CLASSDEF'
            return s:cache[typename]
        elseif get(ci, 'tag', '') == 'PACKAGE'
            return {}
        endif
    endif

    " The standard search order of a simple type name is as follows:
    " 1. The current type including inherited types.
    " 2. A nested type of the current type.
    " 3. Explicitly named imported types (single type import).
    " 4. Other types declared in the same package. Not only current directory.
    " 5. Implicitly named imported types (import on demand).

    " 1 & 2.
    " NOTE: inherited types are treated as normal
    if filekey == s:GetCurrentFileKey()
        let simplename = typename[strridx(typename, '.')+1:]
        if s:FoundClassDeclaration(simplename) != 0
            let ci = s:GetClassInfoFromSource(simplename, '%')
            " do not cache it
            if !empty(ci)
                return ci
            endif
        endif
    else
        let ci = s:GetClassInfoFromSource(typename, filekey)
        if !empty(ci)
            return ci
        endif
    endif

    " 3.
    " NOTE: PackageName.Ident, TypeName.Ident
    let fqn = s:SearchSingleTypeImport(typename, s:GetImports('imports_fqn', filekey))
    if !empty(fqn)
        call s:DoGetTypeInfoForFQN([fqn], srcpath)
        let ti = get(s:cache, fqn, {})
        if get(ti, 'tag', '') != 'CLASSDEF'
            " TODO: mark the wrong import declaration.
        endif
        return ti
    endif

    " 4 & 5
    " NOTE: Keeps the fqn of the same package first!!
    let fqns = [empty(packagename) ? typename : packagename . '.' . typename]
    for p in s:GetImports('imports_star', filekey)
        call add(fqns, p . typename)
    endfor
    call s:DoGetTypeInfoForFQN(fqns, srcpath)
    for fqn in fqns
        if has_key(s:cache, fqn)
            return get(s:cache[fqn], 'tag', '') == 'CLASSDEF' ? s:cache[fqn] : {}
        endif
    endfor

    return {}
endfu

" Rules of overriding and hiding:
" 1. Fields cannot be overridden; they can only be hidden.
"    In the subclass, the hidden field of superclass can no longer be accessed
"    directly by its simple name. `super` or another reference must be used.
" 2. A method can be overriden only if it is accessible.
"    When overriding methods, both the signature and return type must be the
"    same as in the superclass.
" 3. Static members cannot be overridden; they can only be hidden
"    -- whether a field or a method. But hiding static members has little effect,
"    because static should be accessed via the name of its declaring class.
" Given optional argument, add protected, default (package) access, private members.
"fu! s:MergeClassInfo(ci, another, ...)
"  if empty(a:another)  | return a:ci    | endif
"
"  if empty(a:ci)
"    let ci = copy(a:another)
""    if a:0 > 0 && a:1
""      call extend(ci.fields, get(a:another, 'declared_fields', []))
""      call extend(ci.methods, get(a:another, 'declared_methods', []))
""    endif
"    return ci
"  endif
"
"  call extend(a:ci.methods, a:another.methods)
"
"  for f in a:another.fields
"    if s:Index(a:ci.fields, f.n, 'n') < 0
"      call add(a:ci.fields, f)
"    endif
"  endfor
"  return a:ci
"endfu


" Parameters:
"   class  the qualified class name
" Return:  TClassInfo or {} when not found
" See ClassInfoFactory.getClassInfo() in insenvim.
function! s:DoGetReflectionClassInfo(fqn)
    if !has_key(s:cache, a:fqn)
        let res= s:reflection.class_info(a:fqn)
        if type(res) == type({})
            let s:cache[a:fqn]= s:Sort(res)
        elseif type(res) =~ type([])
            for type in res
                if get(type, 'name', '') != ''
                    let s:cache[type.name]= s:Sort(type)
                endif
            endfor
        else
            throw printf('javacomplete: %s', string(res))
        endif
    endif
    return get(s:cache, a:fqn, {})
endfunction

fu! s:GetClassInfoFromSource(class, filename)
    let ci = {}
    if len(tagfiles()) > 0
        let ci = s:DoGetClassInfoFromTags(a:class)
    endif

    if empty(ci)
        let unit = javacomplete#parse(a:filename)
        let targetPos = a:filename == '%' ? java_parser#MakePos(line('.')-1, col('.')-1) : -1
        for t in s:SearchTypeAt(unit, targetPos, 1)
            if t.name == a:class
                let t.filepath = a:filename == '%' ? s:GetCurrentFileKey() : expand(a:filename)
                return s:Tree2ClassInfo(t)
                "return s:AddInheritedClassInfo(s:Tree2ClassInfo(t), t)
            endif
        endfor
    endif
    return ci
endfu

fu! s:Tree2ClassInfo(t)
    let t = a:t

    " fill fields and methods
    let t.fields = []
    let t.methods = []
    let t.ctors = []
    let t.classes = []
    for def in t.defs
        if def.tag == 'METHODDEF'
            call add(def.n == t.name ? t.ctors : t.methods, def)
        elseif def.tag == 'VARDEF'
            call add(t.fields, def)
        elseif def.tag == 'CLASSDEF'
            call add(t.classes, t.fqn . '.' . def.name)
        endif
    endfor

    " convert type name in extends to fqn for class defined in source files
    if !has_key(a:t, 'classpath') && has_key(a:t, 'extends')
        if has_key(a:t, 'filepath') && a:t.filepath != s:GetCurrentFileKey()
            let filepath = a:t.filepath
            let packagename = get(s:files[filepath].unit, 'package', '')
        else
            let filepath = expand('%:p')
            let packagename = s:GetPackageName()
        endif

        let extends = a:t.extends
        let i = 0
        while i < len(extends)
            let ci = s:DoGetClassInfo(java_parser#type2Str(extends[i]), filepath, packagename)
            if has_key(ci, 'fqn')
                let extends[i] = ci.fqn
            endif
            let i += 1
        endwhile
    endif

    return t
endfu

"fu! s:AddInheritedClassInfo(ci, t, ...)
"  let ci = a:ci
"  " add inherited fields and methods
"  let list = []
"  for i in get(a:t, 'extends', [])
"    call add(list, java_parser#type2Str(i))
"  endfor
"
"  if has_key(a:t, 'filepath') && a:t.filepath != expand('%:p')
"    let filepath = a:t.filepath
"    let props = get(s:files, a:t.filepath, {})
"    let packagename = get(props.unit, 'package', '')
"  else
"    let filepath = expand('%:p')
"    let packagename = s:GetPackageName()
"  endif
"
"  for id in list
"    let ci = s:MergeClassInfo(ci, s:DoGetClassInfo(id, filepath, packagename), a:0 > 0 && a:1)
"  endfor
"  return ci
"endfu

" To obtain information of the class in current file or current folder, or
" even in current project.
function! s:DoGetClassInfoFromTags(class)
    " find tag of a:class declaration
    let tags = taglist('^' . a:class)
    let filename = ''
    let cmd = ''
    for tag in tags
        if has_key(tag, 'kind')
            if tag['kind'] == 'c'
                let filename = tag['filename']
                let cmd = tag['cmd']
                break
            endif
        endif
    endfor

    let tags = taglist('^' . (empty(b:javacomplete_context.incomplete) ? '.*' : b:javacomplete_context.incomplete) )
    if filename != ''
        call filter(tags, "v:val['filename'] == '" . filename . "' && has_key(v:val, 'class') ? v:val['class'] == '" . a:class . "' : 1")
    endif

    let ci = {'name': a:class}
    " extends and implements
    let ci['ctors'] = []
    let ci['fields'] = []
    let ci['methods'] = []

    " members
    for tag in tags
        let member = {'n': tag['name']}

        " determine kind
        let kind = 'm'
        if has_key(tag, 'kind')
            let kind = tag['kind']
        endif

        let cmd = tag['cmd']
        if cmd =~ '\<static\>'
            let member['m'] = '1000'
        else
            let member['m'] = ''
        endif

        let desc = substitute(cmd, '/^\s*', '', '')
        let desc = substitute(desc, '\s*{\?\s*$/$', '', '')

        if kind == 'm'
            " description
            if cmd =~ '\<static\>'
                let desc = substitute(desc, '\s\+static\s\+', ' ', '')
            endif
            let member['d'] = desc

            let member['p'] = ''
            let member['r'] = ''
            if tag['name'] == a:class
                call add(ci['ctors'], member)
            else
                call add(ci['methods'], member)
            endif
        elseif kind == 'f'
            let member['t'] = substitute(desc, '\([a-zA-Z0-9_[\]]\)\s\+\<' . tag['name'] . '\>.*$', '\1', '')
            call add(ci['fields'], member)
        endif
    endfor
    return ci
endfu

" package information              {{{2

" search in members              {{{2
" TODO: what about default access?
" public for all              
" protected for this or super 
" private for this            
fu! s:CanAccess(mods, kind)
    return (a:mods[-4:-4] || a:kind/10 == 0)
    \ &&   (a:kind == 1 || a:mods[-1:]
    \  || (a:mods[-3:-3] && (a:kind == 1 || a:kind == 2))
    \  || (a:mods[-2:-2] && a:kind == 1))
endfu

fu! s:SearchMember(ci, name, fullmatch, kind, returnAll, memberkind, ...)
    let result = [[], [], []]

    if a:kind != 13
        for m in (a:0 > 0 && a:1 ? [] : get(a:ci, 'fields', [])) + ((a:kind == 1 || a:kind == 2) ? get(a:ci, 'declared_fields', []) : [])
            if empty(a:name) || (a:fullmatch ? m.n ==# a:name : m.n =~# '^' . a:name)
                if s:CanAccess(m.m, a:kind)
                    call add(result[2], m)
                endif
            endif
        endfor

        for m in (a:0 > 0 && a:1 ? [] : get(a:ci, 'methods', [])) + ((a:kind == 1 || a:kind == 2) ? get(a:ci, 'declared_methods', []) : [])
            if empty(a:name) || (a:fullmatch ? m.n ==# a:name : m.n =~# '^' . a:name)
                if s:CanAccess(m.m, a:kind)
                    call add(result[1], m)
                endif
            endif
        endfor
    endif

    if a:kind/10 != 0
        let types = get(a:ci, 'classes', [])
        for t in types
            if empty(a:name) || (a:fullmatch ? t[strridx(t, '.')+1:] ==# a:name : t[strridx(t, '.')+1:] =~# '^' . a:name)
                if !has_key(s:cache, t) || !has_key(s:cache[t], 'flags') || a:kind == 1 || s:cache[t].flags[-1:]
                    call add(result[0], t)
                endif
            endif
        endfor
    endif

    " key `classpath` indicates it is a loaded class from classpath
    " All public members of a loaded class are stored in current ci
    if !has_key(a:ci, 'classpath') || (a:kind == 1 || a:kind == 2)
        for i in get(a:ci, 'extends', [])
            let ci = s:DoGetClassInfo(java_parser#type2Str(i))
            let members = s:SearchMember(ci, a:name, a:fullmatch, a:kind == 1 ? 2 : a:kind, a:returnAll, a:memberkind)
            let result[0] += members[0]
            let result[1] += members[1]
            let result[2] += members[2]
        endfor
    endif
    return result
endfu


" generate member list              {{{2

fu! s:DoGetFieldList(fields)
    let s = ''
    for field in a:fields
        let s .= "{'kind':'" . (s:IsStatic(field.m) ? "F" : "f") . "','word':'" . field.n . "','menu':'" . field.t . "','dup':1},"
    endfor
    return s
endfu

fu! s:DoGetMethodList(methods, ...)
    let paren = a:0 == 0 || !a:1 ? '(' : ''
    let s = ''
    for method in a:methods
        " Substitute throws
        let method.d = substitute(method.d, '\s\+throws\s\+.*', '', '')
        let s .= "{
        \ 'kind':'" . (s:IsStatic(method.m) ? "M" : "m") . "',
        \ 'word':'" . method.n . paren . "',
        \ 'abbr':'" . method.n . "()',
        \ 'menu':'" . method.d . "',
        \ 'dup':'1'},"
    endfor
    return s
endfu

" kind:
"  0 - for instance, 1 - this, 2 - super, 3 - class, 4 - array, 5 - method result, 6 - primitive type
"  11 - for type, with `class` and static member and nested types.
"  12 - for import static, no lparen for static methods
"  13 - for import or extends or implements, only nested types
"  20 - for package
fu! s:DoGetMemberList(ci, kind)
    if type(a:ci) != type({}) || a:ci == {}
        return []
    endif

    let s = a:kind == 11 ? "{'kind': 'C', 'word': 'class', 'menu': 'Class'}," : ''

    let members = s:SearchMember(a:ci, '', 1, a:kind, 1, 0, a:kind == 2)

    " add accessible member types
    if a:kind / 10 != 0
        " Use dup here for member type can share name with field.
        for class in members[0]
            "for class in get(a:ci, 'classes', [])
            let v = get(s:cache, class, {})
            if v == {} || v.flags[-1:]
                let s .= "{'kind': 'C', 'word': '" . substitute(class, a:ci.name . '\.', '\1', '') . "','dup':1},"
            endif
        endfor
    endif

    if a:kind != 13
        let fieldlist = []
        let sfieldlist = []
        for field in members[2]
            "for field in get(a:ci, 'fields', [])
            if s:IsStatic(field['m'])
                call add(sfieldlist, field)
            elseif a:kind / 10 == 0
                call add(fieldlist, field)
            endif
        endfor

        let methodlist = []
        let smethodlist = []
        for method in members[1]
            if s:IsStatic(method['m'])
                call add(smethodlist, method)
            elseif a:kind / 10 == 0
                call add(methodlist, method)
            endif
        endfor

        if a:kind / 10 == 0
            let s .= s:DoGetFieldList(fieldlist)
            let s .= s:DoGetMethodList(methodlist)
        endif
        let s .= s:DoGetFieldList(sfieldlist)
        let s .= s:DoGetMethodList(smethodlist, a:kind == 12)

        let s = substitute(s, '\<' . a:ci.name . '\.', '', 'g')
        let s = substitute(s, '\<java\.lang\.', '', 'g')
        let s = substitute(s, '\<\(public\|static\|synchronized\|transient\|volatile\|final\|strictfp\|serializable\|native\)\s\+', '', 'g')
    endif
    return eval('[' . s . ']')
endfu

" interface              {{{2

function! s:GetMemberList(class)
    if s:IsBuiltinType(a:class)
        return []
    endif

    " FIXME: broken for java.lang.String
    return s:DoGetMemberList(s:DoGetClassInfo(a:class), 0)
endfunction

fu! s:GetStaticMemberList(class)
    return s:DoGetMemberList(s:DoGetClassInfo(a:class), 11)
endfu

function! s:GetConstructorList(class)
    let ci = s:DoGetClassInfo(a:class)
    if empty(ci)
        return []
    endif

    let s = ''
    for ctor in get(ci, 'ctors', [])
        let s .= "{'kind': '+', 'word':'". a:class . "(','abbr':'" . ctor.d . "','dup':1},"
    endfor

    let s = substitute(s, '\<java\.lang\.', '', 'g')
    let s = substitute(s, '\<public\s\+', '', 'g')
    return eval('[' . s . ']')
endfunction

" Name can be a (simple or qualified) package name, or a (simple or qualified)
" type name.
function! s:GetMembers(context, fqn, ...)
    let list= []
    let is_class= 0

    " check existance and read information given fqn
    let package= s:reflection.package_info(a:fqn)
    if !empty(package)
        if a:context.context_type == s:CONTEXT_IMPORT_STATIC || a:context.context_type == s:CONTEXT_IMPORT
            let list+= [{'kind': 'P', 'word': '*;'}]
        endif
        if a:context.context_type !=# s:CONTEXT_PACKAGE_DECL
            for class in sort(get(package, 'classes', []))
                let list+= [{'kind': 'C', 'word': class}]
            endfor
            if exists('class')
                unlet class
            endif
        endif
        for subpkg in sort(get(package, 'subpackages', []))
            let list+= [{'kind': 'P', 'word': subpkg}]
        endfor
    endif

    let class= s:reflection.class_info(a:fqn)
    if !empty(class)
        let list+= s:DoGetMemberList(class, a:context.context_type ==# s:CONTEXT_IMPORT || a:context.context_type ==# s:CONTEXT_NEED_TYPE ? 13 : a:context.context_type ==# s:CONTEXT_IMPORT_STATIC ? 12 : 11)
        let is_class= 1
    endif

    if !is_class
        let list+= s:DoGetPackageInfoInDirs(a:fqn, a:context.context_type ==# s:CONTEXT_PACKAGE_DECL)
    endif

    return list
endfunction

" a:1    incomplete mode
" return packages in classes directories or source pathes
fu! s:DoGetPackageInfoInDirs(package, onlyPackages, ...)
    let list = []

    let pathes = s:GetSourceDirs(expand('%:p'))
    for path in s:GetClassDirs()
        if index(pathes, path) <= 0
            call add(pathes, path)
        endif
    endfor

    let globpattern  = a:0 > 0 ? a:package . '*' : substitute(a:package, '\.', '/', 'g') . '/*'
    let matchpattern = a:0 > 0 ? a:package : a:package . '[\\/]'
    for f in split(globpath(join(pathes, ','), globpattern), "\n")
        for path in pathes
            let idx = matchend(f, escape(path, ' \') . '[\\/]\?\C' . matchpattern)
            if idx != -1
                let name = (a:0 > 0 ? a:package : '') . strpart(f, idx)
                if f[-5:] == '.java'
                    if !a:onlyPackages
                        call add(list, {'kind': 'C', 'word': name[:-6]})
                    endif
                elseif name =~ '^' . s:RE_IDENTIFIER . '$' && isdirectory(f) && f !~# 'CVS$'
                    call add(list, {'kind': 'P', 'word': name})
                endif
            endif
        endfor
    endfor
    return list
endfu
" }}}
"}}}

" Android support

function! s:shellslash(path)
    if exists('+shellslash') && !&shellslash
        return s:gsub(a:path,'\\','/')
    else
        return a:path
    endif
endfunction

fu! s:GetAndroidProjectRoot(path)
    if exists('b:android_project_root')
        return b:android_project_root
    endif

    let root = s:shellslash(simplify(fnamemodify(a:path, ':p:s?[\/]$??')))
    let previous = ""
    while root !=# previous
        let dir = globpath(root, "AndroidManifest.xml")
        if dir != ''
            let b:android_project_root = root
            return root
        endif
        let previous = root
        let root = fnamemodify(root, ':h')
    endwhile

    return ''
endfu

fu! s:GetAndroidClassPath(path)
    if s:GetAndroidProjectRoot(a:path) == ''
        return ""
    endif

    if !(exists('s:android_project_classpath_cache'))
        let s:android_project_classpath_cache = {}
    endif

    if has_key(s:android_project_classpath_cache, s:GetAndroidProjectRoot(a:path))
        return s:android_project_classpath_cache[s:GetAndroidProjectRoot(a:path)]
    endif

    let buildfile = globpath(&rtp, 'autoload/android_listclasspath.xml')
    if buildfile == ''
        return ""
    endif
    let msg = s:P.system('ant -q -f "' . buildfile . '" -Dbasedir="' . s:GetAndroidProjectRoot(a:path) . '" listclasspath')
    let classpath = substitute(msg, '.\{-}CLASSPATH{\([^}]*\)}.*', '\=submatch(1)', "")
    let s:android_project_classpath_cache[s:GetAndroidProjectRoot(a:path)] = classpath

    return classpath
endfu

fu! s:GetCurrentAndroidClassPath()
    return s:GetAndroidClassPath(expand('%:p'))
endfu

fu! javacomplete#AddAndroidClassPath()
    call javacomplete#AddClassPath(s:GetCurrentAndroidClassPath())
endfu
