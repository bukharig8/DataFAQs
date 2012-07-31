#3> <> prov:specializationOf <#TEMPLATE/path/to/public/source-code.py>;
#3>    rdfs:seeAlso <https://github.com/timrdf/DataFAQs/wiki/FAqT-Service> .

import faqt

import sadi
from rdflib import *
import surf

from surf import *
from surf.query import a, select

import rdflib
rdflib.plugin.register('sparql', rdflib.query.Processor,
                       'rdfextras.sparql.processor', 'Processor')
rdflib.plugin.register('sparql', rdflib.query.Result,
                       'rdfextras.sparql.query', 'SPARQLQueryResult')

import httplib
from urlparse import urlparse, urlunparse
import urllib
import urllib2

from BeautifulSoup import BeautifulSoup

# These are the namespaces we are using beyond those already available
# (see http://packages.python.org/SuRF/modules/namespace.html#registered-general-purpose-namespaces)
ns.register(moat='http://moat-project.org/ns#')
ns.register(ov='http://open.vocab.org/terms/')
ns.register(void='http://rdfs.org/ns/void#')
ns.register(dcat='http://www.w3.org/ns/dcat#')
ns.register(dcterms='http://purl.org/dc/terms/')
ns.register(sd='http://www.w3.org/ns/sparql-service-description#')
ns.register(conversion='http://purl.org/twc/vocab/conversion/')
ns.register(datafaqs='http://purl.org/twc/vocab/datafaqs#')
ns.register(sioc='http://rdfs.org/sioc/ns#')
ns.register(hello='http://sadiframework.org/examples/hello.owl#')

# The Service itself
class W3CMailingListPerMonth(faqt.Service):

   # Service metadata.
   label                  = 'w3c-mail-archives-per-month'
   serviceDescriptionText = 'Returns an RDF description of the given W3C Mailing List.'
   comment                = ''
   serviceNameText        = 'w3c-mail-archives-per-month' # Convention: Match 'name' below.
   name                   = 'w3c-mail-archives-per-month' # This value determines the service URI relative to http://localhost:9229/
                                                          # Convention: Use the name of this file for this value.
   dev_port = 9230

   def __init__(self):
      # DATAFAQS_PROVENANCE_CODE_RAW_BASE                   +  servicePath  +  '/'  + self.serviceNameText
      # DATAFAQS_PROVENANCE_CODE_PAGE_BASE                  +  servicePath  +  '/'  + self.serviceNameText
      #
      # ^^ The source code location
      #    aligns with the deployment location \/
      #
      #                 DATAFAQS_BASE_URI  +  '/datafaqs/'  +  servicePath  +  '/'  + self.serviceNameText
      faqt.Service.__init__(self, servicePath = 'services/sadi/faqt/discuss')

   def getOrganization(self):
      result                      = self.Organization()
      result.mygrid_authoritative = True
      result.protegedc_creator    = 'lebot@rpi.edu'
      result.save()
      return result

   # This archive was generated by hypermail 2.2.0+W3C-0.50
   def getInputClass(self):
      return ns.SIOC['Container'] # e.g. http://lists.w3.org/Archives/Public/public-prov-wg/2012Mar

   def getOutputClass(self):
      return ns.DATAFAQS['EvaluatedDataset']

   def process(self, input, output):

      print 'processing ' + input.subject
      base = re.sub('/author?$','',input.subject)

      # Query the RDF graph POSTed: input.session.default_store.execute
      # [] a hello:SecondaryParameters; 
      #   hello:author_identification_stance hello:conservative .
      query = select('?stance').where(('?parameters', a, ns.HELLO['SecondaryParameters']),
                                      ('?parameters', ns.HELLO['author_identification_stance'], ns.HELLO['conservative']))
      conservative = True if len(input.session.default_store.execute(query)) else False
      print 'conservative: ' + str(conservative)

      Item = output.session.get_class(ns.SIOC['Item'])

      page  = urllib2.urlopen(input.subject)
      soup  = BeautifulSoup(page)

      for author in soup.findAll('div', {'class':'messages-list'})[0].findAll('ul')[0].findAll('li',recursive=False):

         authorName = author.findAll('dfn')[0].string
         for message in author.findAll('ul')[0].findAll('li'):
            anchors   = message.findAll('a')
            page      = anchors[0]['href'].replace('.html','')
            subject   = anchors[0].string
            name      = anchors[1]['name']
            messageID = anchors[1]['id']
            date      = anchors[1].findAll('em')[0].string

            print '  ' + page + ' ' + subject
            print '    (' + name + ' ' + messageID + ' ' + date + ')'

            #  Cresswell, Stephen
            #     0003.html RE: PROV-ISSUE-410 (prov-primer-review): Feedback on Primer document   [Primer]
            #       (msg3 msg3 (Sunday,  1 July))

            # <http://lists.w3.org/Archives/Public/public-prov-wg/2012Jul/0003> a sioc:Item;
            #    dcterms:identifier "msg3";
            #    dcterms:title "RE: PROV-ISSUE-410 (prov-primer-review): Feedback on Primer document   [Primer]";
            #    dcterms:date "Sunday, 1 July";
            #    sioc:has_container <http://lists.w3.org/Archives/Public/public-prov-wg/2012Mar>;
            # .         

            item = Item(base + '/' + page)
            item.sioc_has_container = output
            item.dcterms_date       = str(date).strip('(').strip(')')
            item.dcterms_identifier = str(messageID)
            item.dcterms_author     = str(authorName)
            item.save()
            output.rdf_type.append(ns.DATAFAQS['Satisfactory'])
         print
         print

      # Walk through all Things in the input graph (using SuRF):
      # Thing = input.session.get_class(ns.OWL['Thing'])
      # for person in Thing.all():

      if ns.DATAFAQS['Satisfactory'] not in output.rdf_type:
         output.rdf_type.append(ns.DATAFAQS['Unsatisfactory'])

      output.save()

# Used when Twistd invokes this service b/c it is sitting in a deployed directory.
resource = W3CMailingListPerMonth()

# Used when this service is manually invoked from the command line (for testing).
if __name__ == '__main__':
   print resource.name + ' running on port ' + str(resource.dev_port) + '. Invoke it with:'
   print 'curl -H "Content-Type: text/turtle" -d @my.ttl http://localhost:' + str(resource.dev_port) + '/' + resource.name
   sadi.publishTwistedService(resource, port=resource.dev_port)
